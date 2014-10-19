class Concord
  extend IB

  outlet :currentFileListAry
  outlet :corpusListAry
  outlet :dbListAry
  outlet :indexedDBListAry
  outlet :concContextView
  outlet :progressBar
  outlet :concSearchBtn

  #outlet :concResultAry
  outlet :concTable

  outlet :searchWordHistoryAryCtl
  outlet :contextWordHistryAryCtl
  outlet :contextExcludeWordHistryAryCtl

  outlet :appInfoObjCtl

  outlet :fileController
  
  attr_accessor :concSearchEndTime, :concCurrentSearchWords, :searchWordHistoryAryCtl, :contextWordHistryAryCtl, :contextExcludeWordHistryAryCtl
  
  
  def awakeFromNib
    @concTable.unbind("sortDescriptors")
    @concContextView.setFont(NSFont.fontWithName("Lucida Grande", size: 13))
    @concContextView.setAutomaticSpellingCorrectionEnabled(false)
    @concContextView.setAutomaticDashSubstitutionEnabled(false)
    @concContextView.setAutomaticDataDetectionEnabled(false)
    @concContextView.setAutomaticQuoteSubstitutionEnabled(false)
    @concContextView.setAutomaticTextReplacementEnabled(false)
    @concSortChoiceLabels = ['concSort1','concSort2','concSort3','concSort4']
    @concResultAry = []
  end

  def applicationDidFinishLaunching(notification)
    @appInfoObjCtl.content['concSearchMode'] = 0
  end
  
  
  def searchConcFromContext(sender)
    if @concResultAry.length > 0
      alert = NSAlert.alertWithMessageText("Do you want to proceed?",
                                          defaultButton:"Proceed",
                                          alternateButton:nil,
                                          otherButton:"Abort",
                                          informativeTextWithFormat:"The search results on the table will be gone.")
      alert.buttons[1].setKeyEquivalent("\e")
      userChoice = alert.runModal
      return if userChoice == -1
    end
    @appInfoObjCtl.content.removeObjectForKey('concContextWord') if !@appInfoObjCtl.content['concContextWord'].nil?
    @appInfoObjCtl.content.removeObjectForKey('concExcludeWord') if Defaults['contextExcludeCheck'] && !@appInfoObjCtl.content['concExcludeWord'].nil?
    @appInfoObjCtl.content['concSearchWord'] = @concContextView.string.substringWithRange(@concContextView.selectedRange)
    self.searchConc(self)
  end
  
  
  
  def searchConc(sender)
    return if @appInfoObjCtl.content['concSearchWord'].strip == ""    
    
    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0 && @fileController.currentFileListAry.arrangedObjects.length == 0
      alert = NSAlert.alertWithMessageText("No file to process on the File Table.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please add at least one file to the File Table.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 0 && NSApp.delegate.inputText.string.length == 0
      alert = NSAlert.alertWithMessageText("Input text is empty.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please copy/paste the text to analyze in the File View.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    elsif Defaults['corpusMode'] == 1 && @fileController.cdListAry[Defaults['mode']].arrangedObjects.select{|x| x['check']}.length == 0
      alert = NSAlert.alertWithMessageText("No #{@fileController.cdLabel[Defaults['mode']]} is selected.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please select at least one #{@fileController.cdLabel[Defaults['mode']]} on the Table.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    end
    
    @currentIndexSearchMode = @appInfoObjCtl.content['concSearchMode'] if Defaults['mode'] == 2
    
    
    t = Time.now
    
    @appInfoObjCtl.content['concKWPositions'] = Hash.new{|hash,key| hash[key] = []}
    #@appInfoObjCtl.content.removeObjectForKey('concFileCount') if @appInfoObjCtl.content['concFileCount']
    #@appInfoObjCtl.content.removeObjectForKey('currentPlotChoice') if @appInfoObjCtl.content['currentPlotChoice']
    @appInfoObjCtl.content['concKWs'] = {}
    @appInfoObjCtl.content['concSearchedDBs'] = Hash.new{|hash,key| hash[key] = []}
    @appInfoObjCtl.content['concInfoSecLength'] = {}
    
    
    NSApp.delegate.progressBar.setIndeterminate(true)
    NSApp.delegate.progressBar.startAnimation(nil)
    
    self.updateWordHistory(@searchWordHistoryAryCtl,@appInfoObjCtl.content['concSearchWord'])
    self.updateWordHistory(@contextWordHistryAryCtl,@appInfoObjCtl.content['concContextWord']) if Defaults['concContextWordCheck'] && !@appInfoObjCtl.content['concContextWord'].nil?
    self.updateWordHistory(@contextExcludeWordHistryAryCtl,@appInfoObjCtl.content['concExcludeWord']) if Defaults['concContextExcludeCheck'] && !@appInfoObjCtl.content['concExcludeWord'].nil?
        
    @concContextView.setString("")
    @concContextView.scrollRangeToVisible([0,0])
    @currentDispItem = nil
    
    @concResultAry.removeObjectsAtIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@concResultAry.length]))      
    @concTable.reloadData
    @concTable.undoManager.removeAllActions
    
    wd = WildWordProcess.new("conc")

    Dispatch::Queue.concurrent.async{

      concResults = self.concProcess(MyString.new(@appInfoObjCtl.content['concSearchWord']).concRegConversion(wd,"conc"),MyString.new(@appInfoObjCtl.content['concContextWord'].to_s).concRegConversion(wd,"conc"),MyString.new(@appInfoObjCtl.content['concExcludeWord'].to_s).concRegConversion(wd,"conc"),Regexp.new(WildWordProcess.new("word").wildWord,Regexp::IGNORECASE),ConcSpanValues[Defaults['concLeftSpan']],ConcSpanValues[Defaults['concRightSpan']],sender.tag)


      if Defaults['concPlotCheck']
        #@appInfoObjCtl.content['concFileCount'] = [foundFileCount,notFoundFileCount]
        @appInfoObjCtl.content['currentPlotChoice'] = Defaults['concPlotChoice']
      end

      if Defaults['mode'] == 2
        concLineDara = concResults[0]
      else
        concLineDara = self.concSort(concResults[0])
      end        
      
      Dispatch::Queue.main.async{
        if not (Defaults['corpusMode'] == 0 && Defaults['mode'] == 1)
          @concTable.tableColumnWithIdentifier('kwic').headerCell.setStringValue("Kwic - #{concResults[0].length} found in #{concResults[1].length} files")
        else
          @concTable.tableColumnWithIdentifier('kwic').headerCell.setStringValue("Kwic - #{concResults[0].length} found")      
        end
        @concResultAry = concLineDara
        @concTable.scrollRowToVisible(0)
        @concTable.reloadData
      }

      @appInfoObjCtl.content['databaseEditorEnable'] = Defaults['scopeOfContextChoice'] != 1 ? 1 : 0
      @appInfoObjCtl.content['databaseEditorHide'] = Defaults['mode'] == 1 && Defaults['corpusMode'] == 1 ? 0 : 1
    
      @concCurrentSearchWords = [[@appInfoObjCtl.content['concSearchWord'],@appInfoObjCtl.content['concContextWord'],@appInfoObjCtl.content['concExcludeWord']]]
      @concSearchBtn.setTag(0)

      @appInfoObjCtl.content['timer'] = Time.now - t #sprintf("%.3f",Time.now - t)

      Dispatch::Queue.main.async{
        NSApp.delegate.progressBar.stopAnimation(nil)
        @concSearchEndTime = Time.now

        if @notFoundFiles.length > 0
          if @notFoundFiles > 5
            nfFileList = "#{@notFoundFiles[0..4].join("\n")} and #{@notFoundFiles.length - 5} more files."
          else
            nfFileList = "#{@notFoundFiles.join("\n")}"
          end
          alert = NSAlert.alertWithMessageText("Some files are not found.",
                                              defaultButton:"OK",
                                              alternateButton:nil,
                                              otherButton:nil,
                                              informativeTextWithFormat:nfFileList)
          return if alert.runModal == 1
        end
      }
    }
    
  end
  

  def concProcess(searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,source)

    concResults = []
    foundFileCount = {}
    @notFoundFiles = []
    @keyOrder = 0
    
    if (Defaults['qouteIncludeCheck'] || Defaults['hyphenIncludeCheck'] || (Defaults['othersIncludeCheck'] && Defaults['partOfWordChars'] != "")) && NSApp.delegate.includeAsPartWordChars != nil
      lpartWordReg = /\w[#{NSApp.delegate.includeAsPartWordChars}]\z/i
      rpartWordReg = /\A[#{NSApp.delegate.includeAsPartWordChars}]\w/i
      pwrFlag = 1 if Defaults['applyIncludeCharInConcSearch']
    end

    contextIncludeSpan = self.contextSpanCheck("include") if !contextWord.nil?
    contextExcludeSpan = self.contextSpanCheck("exclude") if !excludeWord.nil? && Defaults['concContextExcludeCheck']
    
    tagProcessItems = Defaults['tagModeEnabled'] ? @fileController.tagPreparation : []

    #if Defaults['scopeOfContextChoice'] == 2
    #  ListItemProcesses.new.eosWordPrepare
    #  sentDivReg = /(\s(?!(?:(?!\s)\W)?\b(?:#{NSApp.delegate.nonEOSWords}))(?:\S+\.))\s+/
    #end

    NSApp.delegate.currentConcScope = Defaults['scopeOfContextChoice']
    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0
      if @fileController.currentFileListAry.arrangedObjects.length > 1
        NSApp.delegate.currentConcMode = 0
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(@fileController.currentFileListAry.arrangedObjects.length)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end
      case Defaults['scopeOfContextChoice']
      when 1
        @fileController.currentFileListAry.arrangedObjects.each do |item|
          autorelease_pool {        
            inText = @fileController.readFileContents(item['path'],item['encoding'],"concord",tagProcessItems,searchWord)
            concProcessed = self.fileConcProcess(item,inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
            concResults.concat(concProcessed)
            foundFileCount[item['path']] = 1 if concProcessed.length > 0
          }
          NSApp.delegate.progressBar.incrementBy(1.0) if @fileController.currentFileListAry.arrangedObjects.length > 1
        end
      else
        @fileController.currentFileListAry.arrangedObjects.each do |item|
          autorelease_pool {        
            inText = @fileController.readFileContents(item['path'],item['encoding'],"concord",tagProcessItems,searchWord)
            #inText.gsub!(sentDivReg,'\1' + "\n") if Defaults['scopeOfContextChoice'] == 2
            concProcessed = self.fileConcProcess(item,inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
            concResults.concat(concProcessed)
            foundFileCount[item['path']] = 1 if concProcessed.length > 0
          }
          NSApp.delegate.progressBar.incrementBy(1.0) if @fileController.currentFileListAry.arrangedObjects.length > 1
        end
      end
      if @fileController.currentFileListAry.arrangedObjects.length > 1
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
    elsif Defaults['mode'] == 0 && Defaults['corpusMode'] == 1
      NSApp.delegate.currentConcMode = 2
      filesToProcess = []
      if source == 20
        @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content['collocCorpusSelection']
      elsif source != 0
        case source
        when 10
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[0][0]]
        when 11
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[0][1]]
        when 30
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[0][2]]
        when 31
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[0][3]]
        end
      end
      
      if @appInfoObjCtl.content['concCorpusSelection'] == 0
        NSApp.delegate.currentCDs = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")
        @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          filesToProcess << [NSMutableArray.arrayWithContentsOfFile(corpusItem['path']),corpusItem['name']]
        end
      else
        corpusName = @fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content['concCorpusSelection']]['name']
        NSApp.delegate.currentCDs = corpusName
        filesToProcess << [NSMutableArray.arrayWithContentsOfFile(@fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content['concCorpusSelection']]['path']),corpusName]
      end
      
      totalFilesToProcess = filesToProcess.inject(0){|num,item| num + item[0].length}
      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end
      
      case Defaults['scopeOfContextChoice']
      when 1
        #@fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          #NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).each do |item|
        filesToProcess.each do |files,corpusItem|
          files.each do |item|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"concord",tagProcessItems,searchWord)
              concProcessed = self.fileConcProcess(item,inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
              concResults.concat(concProcessed)
              foundFileCount[item['path']] = 1 if concProcessed.length > 0
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      else
        #@fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          #NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).each do |item|
        filesToProcess.each do |files,corpusItem|
          files.each do |item|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"concord",tagProcessItems,searchWord)
              #inText.gsub!(sentDivReg,'\1' + "\n") if Defaults['scopeOfContextChoice'] == 2
              concProcessed = self.fileConcProcess(item,inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
              concResults.concat(concProcessed)
              foundFileCount[item['path']] = 1 if concProcessed.length > 0
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      end
      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
      
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 0
      NSApp.delegate.currentConcMode = 1
      inText = NSApp.delegate.inputText.string.dup
      inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
      inText = @fileController.tagApplication(inText,tagProcessItems,"concord","current") if Defaults['tagModeEnabled']
      
      #inText.gsub!(sentDivReg,'\1' + "\n") if Defaults['scopeOfContextChoice'] == 2
      
      return [] if inText.length == 0
      concProcessed = self.fileConcProcess({'path' => "current","filename" => "textView",'encoding' => 0},inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan).each
      concResults.concat(concProcessed)
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 1
      NSApp.delegate.currentConcMode = 3
      #NSApp.delegate.progressBar.setIndeterminate(true)
      #NSApp.delegate.progressBar.startAnimation(nil)
      
      filesToProcess = []
      totalFilesToProcess = 0
      
      if source == 20
        @appInfoObjCtl.content['concDatabaseSelection'] = @appInfoObjCtl.content['collocDatabaseSelection']
      elsif source != 0
        case source
        when 10
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[1][0]]
        when 11
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[1][1]]
        when 30
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[1][2]]
        when 31
          @appInfoObjCtl.content['concCorpusSelection'] = @appInfoObjCtl.content[@fileController.cdSelection[1][3]]
        end        
      end
      if @appInfoObjCtl.content['concDatabaseSelection'] == 0
        @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          filesToProcess << [corpusItem['path'],corpusItem['name']]
        end
      else
        path = @fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content['concDatabaseSelection']]['path']
        filesToProcess << [path,@fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content['concDatabaseSelection']]['name']]
      end

      if totalFilesToProcess > 1 && Defaults['scopeOfContextChoice'] == 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end
      NSApp.delegate.currentCDs = filesToProcess.map{|x| x[0]}.join(",")
            
      #NSApp.delegate.currentCDs = @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['path']}
      case Defaults['scopeOfContextChoice']
      when 1
        dbFileCount = 0
        filesToProcess.each_with_index do |item,idx|
          autorelease_pool {        
            db = FMDatabase.databaseWithPath(item[0])
            db.open
              db.beginTransaction
            	  fileCount = 0
                results = db.executeQuery("SELECT DISTINCT file_name, path, file_id, encoding FROM conc_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql}")
                while results.next
                  entryItem = results.resultDictionary
                  textResult = db.executeQuery("select text, id from conc_data where file_id == ? order by id",entryItem['file_id'])
                  textAry = []
                  while textResult.next
                    textAry << textResult.resultDictionary['text']
                  end
                  results2.close
                  inText = textAry.join("\n\n")
                  concProcessed = self.fileConcProcess({'dbPath' => item[0], 'filename' => eachFname, 'corpus' => item[1], 'path' => eachPath, 'encoding' => encoding.to_i , 'fileID' => fileID},inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
                  concResults.concat(concProcessed)
                  foundFileCount[[eachFname,eachPath]] = 1 if concProcessed.length > 0
                  fileCount += 1
                end
                results.close
              db.commit
            db.close
          }
        end
      when 0,2
        filesToProcess.each_with_index do |item,idx|
          fileCount = 0
          autorelease_pool {
            db = FMDatabase.databaseWithPath(item[0])
            db.open
              results = db.executeQuery("SELECT file_name, text, path, file_id, id, encoding FROM conc_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql}#{@appInfoObjCtl.content['concContextWord'].nil? ? "" : MyString.new(@appInfoObjCtl.content['concContextWord']).toSql.gsub(/WHERE/,"AND")}")
              while results.next
                entryItem = results.resultDictionary
                concProcessed = self.fileConcProcess({'dbPath' => item[0], 'filename' => entryItem['file_name'], 'corpus' => item[1], 'path' => entryItem['path'], 'encoding' => entryItem['encoding'].to_i, 'entryID' => entryItem['id'], 'fileID' => entryItem['file_id']},entryItem['text'],searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
                concResults.concat(concProcessed)
                foundFileCount[[entryItem['file_name'],item[0]]] = 1 if concProcessed.length > 0
              end 
              results.close
            db.close
          }
        end
      end
    elsif Defaults['mode'] == 2 && Defaults['corpusMode'] == 1
      NSApp.delegate.currentConcMode = 4
      item = @fileController.indexedDBListAry.arrangedObjects.select{|x| x['check']}[0]      
      
      case @appInfoObjCtl.content['concSortChoice']
      when false
        sortOrderLabels = []
        sortOrder = []
        @appInfoObjCtl.content['concSortSelect'].split("-").each do |label|
          if SortOrderLabels[label] >= 11 || SortOrderLabels[label] <= 15
            adjust = @appInfoObjCtl.content['concSearchMode']
          else
            adjust = 0
          end
          sortOrder << SortOrderLabels[label] + adjust
          sortOrderLabels << SortOrderlabelAry[SortOrderLabels[label] + adjust]
        end
        if sortOrder.length == 3  
          sortOrder << 21
          sortOrderLabels << "file_name"
        end
        @appInfoObjCtl.content['concSortOrder'] = sortOrder
      when true
        sortOrder = []
        @concSortChoiceLabels.each do |label|
          if @appInfoObjCtl.content[label] >= 11 || @appInfoObjCtl.content[label] <= 15
            adjust = @appInfoObjCtl.content['concSearchMode']
          else
            adjust = 0
          end
          sortOrder << @appInfoObjCtl.content[label] + adjust
        end
        @appInfoObjCtl.content['concSortOrder'] = sortOrder        
        sortOrderLabels = [SortOrderlabelAry[sortOrder[0]],SortOrderlabelAry[sortOrder[1]],SortOrderlabelAry[sortOrder[2]],SortOrderlabelAry[sortOrder[3]]]
      end

      autorelease_pool {
        db = FMDatabase.databaseWithPath(item['path'])
        db.open
          case @appInfoObjCtl.content['concSearchMode']
          when 0
            if @appInfoObjCtl.content['concSearchWord'].match(/\?|\!|\*|\||\//)
              results = db.executeQuery("SELECT * FROM conc_idx_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql.gsub("text like", "keyw like")} ORDER BY #{sortOrderLabels.join(",")}")
            else
              results = db.executeQuery("SELECT * FROM conc_idx_data where keyw = '#{@appInfoObjCtl.content['concSearchWord'].downcase}' ORDER BY #{sortOrderLabels.join(",")}")
            end
            keyItem = 'keyw'
            keyLength = 'key_pos_len'
          when 1
            if @appInfoObjCtl.content['concSearchWord'].match(/\?|\!|\*|\||\//)
              results = db.executeQuery("SELECT * FROM conc_idx_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql.gsub("text like", "key2 like")} ORDER BY #{sortOrderLabels.join(",")}")
            else
              results = db.executeQuery("SELECT * FROM conc_idx_data where key2 = '#{@appInfoObjCtl.content['concSearchWord'].downcase}' ORDER BY #{sortOrderLabels.join(",")}")
            end
            keyItem = 'key2'
            keyLength = 'key2_pos_len'
          when 2
            if @appInfoObjCtl.content['concSearchWord'].match(/\?|\!|\*|\||\//)
              results = db.executeQuery("SELECT * FROM conc_idx_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql.gsub("text like", "key3 like")} ORDER BY #{sortOrderLabels.join(",")}")
            else
              results = db.executeQuery("SELECT * FROM conc_idx_data where key3 = '#{@appInfoObjCtl.content['concSearchWord'].downcase}' ORDER BY #{sortOrderLabels.join(",")}")
            end
            keyItem = 'key3'
            keyLength = 'key3_pos_len'
          when 3
            if @appInfoObjCtl.content['concSearchWord'].match(/\?|\!|\*|\||\//)
              results = db.executeQuery("SELECT * FROM conc_idx_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql.gsub("text like", "key4 like")} ORDER BY #{sortOrderLabels.join(",")}")
            else
              results = db.executeQuery("SELECT * FROM conc_idx_data where key4 = '#{@appInfoObjCtl.content['concSearchWord'].downcase}' ORDER BY #{sortOrderLabels.join(",")}")
            end
            keyItem = 'key4'
            keyLength = 'key4_pos_len'
          when 4
            if @appInfoObjCtl.content['concSearchWord'].match(/\?|\!|\*|\||\//)
              results = db.executeQuery("SELECT * FROM conc_idx_data #{MyString.new(@appInfoObjCtl.content['concSearchWord']).toSql.gsub("text like", "key5 like")} ORDER BY #{sortOrderLabels.join(",")}")
            else
              results = db.executeQuery("SELECT * FROM conc_idx_data where key5 = '#{@appInfoObjCtl.content['concSearchWord'].downcase}' ORDER BY #{sortOrderLabels.join(",")}")
            end
            keyItem = 'key5'
            keyLength = 'key5_pos_len'
          end  
          
          while results.next
            entryItem = results.resultDictionary
            next if !entryItem[keyItem].match(searchWord)
            concResultHash = {}
            concResultHash['filename'] = entryItem['file_name']
            concResultHash['corpus'] = item['name']
            concResultHash['path'] = entryItem['path']
            concResultHash['dbPath'] = item['path']
            concResultHash['encoding'] = entryItem['encoding']
            concResultHash['entryID'] = entryItem['id']
            concResultHash['fileID'] = entryItem['file_id']
            concResultHash['keyPos'] = [entryItem['key_pos_loc'],entryItem[keyLength]] ## need this on the database
            concResultHash['searchLevel'] = 0
            concResultHash['delPos'] = [entryItem['r1_pos_loc'],entryItem[keyLength] - entryItem['key_pos_len']] if @appInfoObjCtl.content['concSearchMode'] != 0

            concResultHash['contextMatch'] = [] ## marking context words to underline
            ## need a process to skip exclude context words here

            if Defaults['keywordBlankCheck']
              kwicOut = [entryItem['left_text'],keyReplace,entryItem['right_text']]
            else
              kwicOut = [entryItem['left_text'],entryItem[keyItem],entryItem['right_text']]
            end
            
            leftWords = [["",[0,0]]] * 5 + [[entryItem['l5'],[entryItem['l5_pos_loc'],entryItem['l5_pos_len']]],[entryItem['l4'],[entryItem['l4_pos_loc'],entryItem['l4_pos_len']]],[entryItem['l3'],[entryItem['l3_pos_loc'],entryItem['l3_pos_len']]],[entryItem['l2'],[entryItem['l2_pos_loc'],entryItem['l2_pos_len']]],[entryItem['l1'],[entryItem['l1_pos_loc'],entryItem['l1_pos_len']]]]
            rightWords = [[entryItem['r1'],[entryItem['r1_pos_loc'],entryItem['r1_pos_len']]],[entryItem['r2'],[entryItem['r2_pos_loc'],entryItem['r2_pos_len']]],[entryItem['r3'],[entryItem['r3_pos_loc'],entryItem['r3_pos_len']]],[entryItem['r4'],[entryItem['r4_pos_loc'],entryItem['r4_pos_len']]],[entryItem['r5'],[entryItem['r5_pos_loc'],entryItem['r5_pos_len']]],[entryItem['r6'],[entryItem['r6_pos_loc'],entryItem['r6_pos_len']]],[entryItem['r7'],[entryItem['r7_pos_loc'],entryItem['r7_pos_len']]],[entryItem['r8'],[entryItem['r8_pos_loc'],entryItem['r8_pos_len']]]] + [["",[0,0]]] * 2
             
            concResultHash['kwic'] = kwicOut
            concResultHash['sortItems'] = leftWords + [[entryItem[keyItem], [entryItem['key_local_pos'],entryItem[keyLength]]]] + rightWords + [[entryItem['file_name'],[0,0]]] + [[@keyOrder,[0,0]]]

            concResults << concResultHash
            foundFileCount[[entryItem['file_name'],item[0]]] = 1
          end 
          results.close
        db.close
      }
    end
    return [concResults,foundFileCount]
  end
  
  
  
  def fileConcProcess(item,inText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan)
    concResults = []
    if NSApp.delegate.currentConcMode == 3 || Defaults['scopeOfContextChoice'] == 1
      if Defaults['concPlotCheck']
        if Defaults['concPlotChoice'] == 1
          fileLength = inText.scan(contextReg).length
        else
          fileLength = inText.length
        end
      else
        fileLength = 0
      end
      keyFound = 0
      inText.scan(searchWord) do
        leftLength = $`.length
        if leftLength >= leftSpan * 2
          leftText = $`[-(leftSpan * 2),leftSpan * 3]
        else
          leftText = $`
        end
        rightText = $'[0,rightSpan * 3]
        keyW = $&
        leftWordLength = Defaults['scopeOfContextChoice'] == 1 && Defaults['concPlotCheck'] && Defaults['concPlotChoice'] == 1 && NSApp.delegate.currentConcMode != 1 ? $`.scan(contextReg).length : 0
        returnItem = self.concCoreProcess(item,keyW,leftText,rightText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan,leftLength,leftWordLength)
        #if Defaults['scopeOfContextChoice'] == 1 && Defaults['concPlotCheck'] && !returnItem.nil? && NSApp.delegate.currentConcMode != 1
        #  if Defaults['concPlotChoice'] == 1
        #    @appInfoObjCtl.content['concKWPositions'][[item['path'],item['corpus']]] << [returnItem['wordKeyPos'],fileLength,0]
        #  else
        #    @appInfoObjCtl.content['concKWPositions'][[item['path'],item['corpus']]] << [returnItem['keyPos'][0],fileLength,0]
        #  end
        #end
        if !returnItem.nil?
          returnItem['fileLength'] = fileLength
          concResults << returnItem
        end
      end
    else
      case Defaults['scopeOfContextChoice']
      when 0
        inText.lines.grep(searchWord) do |paragraph|
          paragraph.scan(searchWord) do
            leftLength = $`.length
            returnItem = self.concCoreProcess(item,$&,$`,$',searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan,leftLength,0)
            concResults << returnItem if not returnItem.nil?
          end
        end
      when 2
        #inText.lines.grep(searchWord) do |paragraph|
          #print "#{paragraph}\n\n"
          #paragraph.scan(searchWord) do
          inText.scan(searchWord) do
            leftLength = $`.length
            returnItem = self.concCoreProcess(item,$&,$`,$',searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan,leftLength,0)
            concResults << returnItem if not returnItem.nil?
          end
        #end
      end
    end
    return concResults
  end
  
  
  
  def concCoreProcess(item,keyW,leftText,rightText,searchWord,contextWord,excludeWord,contextReg,leftSpan,rightSpan,lpartWordReg,rpartWordReg,pwrFlag,contextIncludeSpan,contextExcludeSpan,leftLength,leftWordLength)
    @appInfoObjCtl.content['concKWs'][keyW.downcase] = 1
    concResultHash = {}
    concResultHash['filename'] = item['filename']
    concResultHash['corpus'] = item['corpus'].to_s
    concResultHash['path'] = item['path']
    concResultHash['dbPath'] = item['dbPath'].to_s
    concResultHash['encoding'] = item['encoding']
    concResultHash['entryID'] = item['entryID'].to_i
    concResultHash['fileID'] = item['fileID'].to_i
    concResultHash['keyPos'] = [leftLength,keyW.length]
    concResultHash['searchLevel'] = 0
    concResultHash['wordKeyPos'] = leftWordLength
        
    if Defaults['keywordBlankCheck']
      case Defaults['keywordBlankChoice']
      when 0
        keyReplace = "(#{" " * Defaults['keywordBlankNum']})"
        keyLength = Defaults['keywordBlankNum'] + 2
      when 1
        keyReplace = "[#{" " * Defaults['keywordBlankNum']}]"
        keyLength = Defaults['keywordBlankNum'] + 2
      when 2
        keyReplace = " " * Defaults['keywordBlankNum']
        keyLength = Defaults['keywordBlankNum']
      end
    else
      keyLength = keyW.length
    end
    return nil if pwrFlag && (leftText.match(lpartWordReg) || rightText.match(rpartWordReg))
    
    if Defaults['concSuppressBlankInContext']
      if (leftExtract = leftText).nil?
        if (lt = leftText.gsub(CRCharLongReg," ").gsub(/\ {2,30}/," "))[-1*leftSpan,leftSpan].nil?
          leftExtract = " " * (leftSpan - lt.length) + lt          
        else
          leftExtract = lt[-1*leftSpan,leftSpan]
        end
      elsif (lt = leftExtract.gsub(CRCharLongReg," ").gsub(/\ {2,30}/," "))[-1*leftSpan,leftSpan].nil?
        leftExtract = " " * (leftSpan - lt.length) + lt
      else
        leftExtract = lt[-1*leftSpan,leftSpan]
      end
      rightExtract = rightText[0,rightSpan*2].gsub(CRCharLongReg," ").gsub(/\ {2,30}/," ")[0,rightSpan]
    else
      if (leftExtract = leftText[-1*leftSpan,leftSpan]).nil?
        leftExtract = " " * (leftSpan - leftLength) + leftText.gsub(CRCharReg," ")
      else
        leftExtract.gsub!(CRCharReg," ")
      end
      rightExtract = rightText[0,rightSpan].gsub(CRCharReg," ")        
      #rightExtract = rightText[/.{0,#{rightSpan}}/].gsub(CRCharReg," ")        
    end
    leftWords = []
    leftExtract.downcase.scan(contextReg) do |var|
      leftWords << [$&,[$`.length,$&.length]]
    end
        
    leftWords = [["",[0,0]]] * (10 - leftWords.last(10).length) + leftWords.last(10)

    rightWords = []
    leftContextLength = leftExtract.length + keyLength
    rightExtract.downcase.scan(contextReg) do |var|
      rightWords << [$&,[leftContextLength + $`.length,$&.length]]
    end
    rightWords = rightWords.first(10) + [["",[0,0]]] * (10 - rightWords.first(10).length)

    if Defaults['concContextWordCheck'] && !contextWord.nil? ######## change this part later ########
      contextInclude = []
      if (begPos = (leftWords + rightWords)[contextIncludeSpan][0][1][0]) < leftContextLength && (endPos = (leftWords + rightWords)[contextIncludeSpan][-1][1][0]) > leftContextLength
        return nil if leftExtract[begPos,leftExtract.length - begPos].match(contextWord).nil? && rightExtract[0,endPos + (leftWords + rightWords)[contextIncludeSpan][-1][1][1]].match(contextWord).nil?
        leftExtract[begPos,leftExtract.length - begPos].scan(contextWord) do
          contextInclude << [begPos + $`.length,$&.length]
        end
        rightExtract[0,endPos + (leftWords + rightWords)[contextIncludeSpan][-1][1][1]].scan(contextWord) do
          contextInclude << [leftContextLength + $`.length,$&.length]
        end
      elsif (begPos = (leftWords + rightWords)[contextIncludeSpan][0][1][0]) < leftContextLength && (endPos = (leftWords + rightWords)[contextIncludeSpan][-1][1][0]) < leftContextLength
        return nil if leftExtract[begPos,leftExtract.length - begPos].match(contextWord).nil?
        leftExtract[begPos,leftExtract.length - begPos].scan(contextWord) do
          contextInclude << [begPos + $`.length,$&.length]
        end
      elsif (begPos = (leftWords + rightWords)[contextIncludeSpan][0][1][0]) > leftContextLength && (endPos = (leftWords + rightWords)[contextIncludeSpan][-1][1][0]) > leftContextLength
        return nil if rightExtract[0,endPos + (leftWords + rightWords)[contextIncludeSpan][-1][1][1]].match(contextWord).nil?
        rightExtract[0,endPos + (leftWords + rightWords)[contextIncludeSpan][-1][1][1]].scan(contextWord) do
          contextInclude << [leftContextLength + $`.length,$&.length]
        end
      end
      
      #return nil if (contextInclude = (leftWords + rightWords)[contextIncludeSpan].select{|x| x[0].match(contextWord)}) == []
      concResultHash['contextMatch'] = contextInclude
    end
    if Defaults['concContextExcludeCheck'] && excludeWord != nil ######## change this part later ########
      if (begPos = (leftWords + rightWords)[contextExcludeSpan][0][1][0]) < leftContextLength && (endPos = (leftWords + rightWords)[contextExcludeSpan][-1][1][0]) > leftContextLength
        return nil if leftExtract[begPos,leftExtract.length - begPos].match(excludeWord) || rightExtract[0,endPos + (leftWords + rightWords)[contextExcludeSpan][-1][1][1]].match(excludeWord)
      elsif (begPos = (leftWords + rightWords)[contextExcludeSpan][0][1][0]) < leftContextLength && (endPos = (leftWords + rightWords)[contextExcludeSpan][-1][1][0]) < leftContextLength
        return nil if leftExtract[begPos,leftExtract.length - begPos].match(excludeWord)
      elsif (begPos = (leftWords + rightWords)[contextExcludeSpan][0][1][0]) > leftContextLength && (endPos = (leftWords + rightWords)[contextExcludeSpan][-1][1][0]) > leftContextLength
        return nil if rightExtract[0,endPos + (leftWords + rightWords)[contextExcludeSpan][-1][1][1]].match(excludeWord)
      end
      
      #return nil if (leftWords + rightWords)[contextExcludeSpan].select{|x| x[0].match(excludeWord)}.length > 0
    end
    
    if Defaults['keywordBlankCheck']
      kwicOut = [leftExtract,keyReplace,rightExtract]
    else
      kwicOut = [leftExtract,keyW,rightExtract]
    end
    concResultHash['kwic'] = kwicOut
    concResultHash['sortItems'] = leftWords + [[keyW.downcase,[leftExtract.length,keyLength]]] + rightWords + [[item['filename'],[0,0]]] + [[@keyOrder,[0,0]]]
    @keyOrder += 1
    return concResultHash
  end
  
  
  def resortConcResult(sender)
    concSortResults = self.concSort(@concResultAry)
    @concResultAry.removeObjectsAtIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@concResultAry.length]))      
    @concResultAry = concSortResults
    @concTable.reloadData
    @concTable.scrollRowToVisible(0)
  end
  
  
  def concSort(concResults)
    @concTable.undoManager.removeAllActions
    if Defaults['mode'] == 2
      case @appInfoObjCtl.content['concSortChoice']
      when false
        sortOrder = []
        @appInfoObjCtl.content['concSortSelect'].split("-").each do |label|
          if SortOrderLabels[label] >= 11 && SortOrderLabels[label] <= 15
            adjust = @appInfoObjCtl.content['concSearchMode']
          else
            adjust = 0
          end
          sortOrder << SortOrderLabels[label] + adjust
        end
        if sortOrder.length == 3
          sortOrder << 21
        end
        @appInfoObjCtl.content['concSortOrder'] = sortOrder
      when true
        sortOrder = []
        @concSortChoiceLabels.each do |label|
          if @appInfoObjCtl.content[label] >= 11 && @appInfoObjCtl.content[label] <= 15
            adjust = @appInfoObjCtl.content['concSearchMode']
          else
            adjust = 0
          end
          sortOrder << @appInfoObjCtl.content[label] + adjust
        end
        @appInfoObjCtl.content['concSortOrder'] = sortOrder
      end
      return concResults.sort_by{|x| [x['sortItems'][@appInfoObjCtl.content['concSortOrder'][0]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][1]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][2]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][3]][0]]}
    else
      case @appInfoObjCtl.content['concSortChoice']
      when false
        sortOrder = []
        @appInfoObjCtl.content['concSortSelect'].split("-").each do |label|
          sortOrder << SortOrderLabels[label]
        end
        sortOrder << 21 if sortOrder.length == 3      
        @appInfoObjCtl.content['concSortOrder'] = sortOrder
      when true
        @appInfoObjCtl.content['concSortOrder'] = [@appInfoObjCtl.content['concSort1'],@appInfoObjCtl.content['concSort2'],@appInfoObjCtl.content['concSort3'],@appInfoObjCtl.content['concSort4']]
      end
      return concResults.sort_by{|x| [x['sortItems'][@appInfoObjCtl.content['concSortOrder'][0]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][1]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][2]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][3]][0]]}
    end
  end
  
  
  def updateWordHistory(aryCtl,word)
    idxToDelete = NSMutableIndexSet.alloc.init
    aryCtl.arrangedObjects.each_with_index do |entry,idx|
      idxToDelete.addIndex(idx) if entry['word'] == word
    end
    aryCtl.removeObjectsAtArrangedObjectIndexes(idxToDelete)
    aryCtl.insertObject({'word' => word},atArrangedObjectIndex:0)

    aryCtl.removeObjectAtArrangedObjectIndex(Defaults['searchWordHistoryNum']) if aryCtl.arrangedObjects.length > Defaults['searchWordHistoryNum']
  end

  
  def contextSpanCheck(source)
    case source
    when "include"
      leftSpan = @appInfoObjCtl.content['concLeftContextSpan']
      rightSpan = @appInfoObjCtl.content['concRightContextSpan']
    when "exclude"
      leftSpan = @appInfoObjCtl.content['concLeftExcludeSpan']
      rightSpan = @appInfoObjCtl.content['concRightExcludeSpan']
    end
    if leftSpan < rightSpan
      return leftSpan..rightSpan
    elsif leftSpan > rightSpan
      return rightSpan..leftSpan
    else
      return leftSpan..rightSpan
    end
  end
  
  
  def copyConcLines(sender)
    pasteBoard = NSPasteboard.pasteboardWithName(NSGeneralPboard)
    pasteBoard.declareTypes([NSStringPboardType,NSPasteboardTypeRTF],owner:self)
    
    case sender.tag
    when 0
      copyText = String.new
      @concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes).each do |item|
        if Defaults['concCopyInsertTab']
          copyText << "#{item['kwic'].join("\t")}\n"
        else
          copyText << "#{item['kwic'].join("")}\n"
        end
      end
      pasteBoard.setString(copyText,forType:NSStringPboardType)
      
    when 1
      copyText = NSMutableAttributedString.alloc.init
      colorPosAdjust1 = Defaults['concCopyInsertTab'] ? 1 : 0
      colorPosAdjust2 = Defaults['concCopyInsertTab'] ? 2 : 0

      @concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes).each do |item|
        if Defaults['concCopyInsertTab']
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join("\t"),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])}).appendAttributedString(NSMutableAttributedString.alloc.initWithString("\n"))
        else
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])}).appendAttributedString(NSMutableAttributedString.alloc.initWithString("\n"))
        end
        if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
          concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [item['kwic'][0].length + colorPosAdjust1,item['kwic'][1].length])        
        end

        if Defaults['concCopyContextColor']
          NSApp.delegate.appInfoObjCtl.content['concSortOrder'].each_with_index do |orderPos,idx|
            if orderPos > 10
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [item['sortItems'][orderPos][1][0] + colorPosAdjust2,item['sortItems'][orderPos][1][1]])
            else
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: item['sortItems'][orderPos][1])
            end
          end
        end
        
        if Defaults['concCopyContextStyle'] && !item['contextMatch'].nil?
          if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
            item['contextMatch'].each do |contextMatch|
              if contextMatch[0] > item['kwic'].length
                concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: [contextMatch[1][0] + colorPosAdjust2,contextMatch[1][1]])
              else
                concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: contextMatch[1])
              end
            end
          else
            item['contextMatch'].each do |contextMatch|
              if contextMatch[0] > item['kwic'].length
                concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range:  [contextMatch[1][0] + colorPosAdjust2,contextMatch[1][1]])
              else
                concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: contextMatch[1])
              end
            end
          end
        end
        copyText.appendAttributedString(concLine)
      end
      copyText.length
      pasteBoard.setData(copyText.RTFFromRange([0,copyText.length],documentAttributes:nil),forType:NSRTFPboardType)
    end
  end
  
  
  def deleteConcLine(sender)
    @concTable.undoManager.registerUndoWithTarget(self, selector: "addBackConcLines:", object: [@concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes),@concTable.selectedRowIndexes])
    @concResultAry.removeObjectAtIndex(@concTable.selectedRowIndexes)
    @concSearchEndTime = Time.now
  end
  
  def addBackConcLines(deletedItems)
    @concResultAry.insertObjects(deletedItems[0], atIndexes:deletedItems[1])    
    @concSearchEndTime = Time.now
  end
  
  
  def openSelectedFile(sender)
    case sender.tag
    when 0
      NSApp.delegate.openSelectedFileInFinder(@concResultAry[@concTable.selectedRow])
    when 1
      NSApp.delegate.openSelectedFileWithApp(@concResultAry[@concTable.selectedRow])      
    when 2
      return if File.extname(@concResultAry[@concTable.selectedRow]['path']).downcase != ".txt" && File.extname(@concResultAry[@concTable.selectedRow]['path']) != ""
      NSApp.delegate.openSelectedFileOnCC(@concResultAry[@concTable.selectedRow])
    when 3
      NSApp.delegate.openSelectedDBEntry(@concResultAry[@concTable.selectedRow])
    end
  end
  
  
  
  
  
  def numberOfRowsInTableView(tableView)
    case tableView
    when @concTable
      @concResultAry ? @concResultAry.length : 0
    end
	end
		

	def tableView(tableView,objectValueForTableColumn:col,row:row)
    case col
    when tableView.tableColumnWithIdentifier('id')
      row + 1
    when tableView.tableColumnWithIdentifier('kwic')
      if Defaults['mode'] == 2
        case @appInfoObjCtl.content['concSearchMode']
        when 0
          concLine = NSMutableAttributedString.alloc.initWithString(@concResultAry[row]['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        when 1
          kwicLine = @concResultAry[row]['kwic'].join("")
          kwicLine[@concResultAry[row]['delPos'][0],@concResultAry[row]['delPos'][1]] = ""
          concLine = NSMutableAttributedString.alloc.initWithString(kwicLine,attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        when 2
          kwicLine = @concResultAry[row]['kwic'].join("")
          kwicLine[@concResultAry[row]['delPos'][0],@concResultAry[row]['delPos'][1]] = ""
          concLine = NSMutableAttributedString.alloc.initWithString(kwicLine,attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        when 3
          kwicLine = @concResultAry[row]['kwic'].join("")
          kwicLine[@concResultAry[row]['delPos'][0],@concResultAry[row]['delPos'][1]] = ""
          concLine = NSMutableAttributedString.alloc.initWithString(kwicLine,attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        when 4
          kwicLine = @concResultAry[row]['kwic'].join("")
          kwicLine[@concResultAry[row]['delPos'][0],@concResultAry[row]['delPos'][1]] = ""
          concLine = NSMutableAttributedString.alloc.initWithString(kwicLine,attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        end
      else
        concLine = NSMutableAttributedString.alloc.initWithString(@concResultAry[row]['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
      end
      if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
        concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [@concResultAry[row]['kwic'][0].length,@concResultAry[row]['kwic'][1].length])
      end

      NSApp.delegate.appInfoObjCtl.content['concSortOrder'].each_with_index do |item,idx|
        concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: @concResultAry[row]['sortItems'][item][1])
      end
      if not @concResultAry[row]['contextMatch'].nil?
        if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
          @concResultAry[row]['contextMatch'].each do |item|
            concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: item)
            #concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: item[1])
          end
        else
          @concResultAry[row]['contextMatch'].each do |item|
            concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: item[1])
          end
        end
      end
      concLine
    when tableView.tableColumnWithIdentifier('filename')
      @concResultAry[row]['filename']
    when tableView.tableColumnWithIdentifier('corpus')
      @concResultAry[row]['corpus']
    end
	end
  
  
	def tableViewSelectionDidChange(notification)
	  case notification.object
    when @concTable
      self.updatePreview(nil)
    end
  end

  
  def updatePreview(sender)
    if Defaults['concContextViewCheck'] != true || @concTable.selectedRow == -1
      @concContextView.setString("")
      return
    end
    item = @concResultAry[@concTable.selectedRow]
    case NSApp.delegate.currentConcMode
    when 1
      if NSApp.delegate.inputText.string == ""
        alert = NSAlert.alertWithMessageText("The text box in File View is empty.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"Please switch to Text mode and copy/paste the original text in the text box in File View.")
        alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
        return
      end
      case NSApp.delegate.currentConcScope
      when 1
        @concContextView.setString(NSApp.delegate.inputText.string)
        keyPos = item['keyPos']
      when 0
        @concContextView.setString("")
        contentText = NSApp.delegate.inputText.string
        contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
        keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        @concContextView.setString(contentText) if @concContextView.string != contentText
      when 2
        @concContextView.setString("")
        @concContextView.setString(NSApp.delegate.inputText.string)
        keyPos = item['keyPos']
      end
    when 3
      if !NSFileManager.defaultManager.fileExistsAtPath(item['dbPath'])
        alert = NSAlert.alertWithMessageText("The original database file is missing.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"Please check if the original database file is in the same directory.")
        alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
        return      
      end
      @concContextView.setString("")
      db = FMDatabase.databaseWithPath(item['dbPath'])
      case NSApp.delegate.currentConcScope
      when 1
        db.open
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            contentText += results.resultDictionary['text'] + "\n\n"
          end
          results.close
          keyPos = item['keyPos']
          @currentDispItem = [item['path']]
          @concContextView.setString(contentText)
        db.close
      when 0
      	db.open
          textAry = []
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            textAry << [results.resultDictionary['text'],results.resultDictionary['id']]
          end
          results.close
          preText = textAry.select{|x| x[1].to_i < item['entryID']}.last(50).map{|x| x[0]}.join("\n\n")
          restText = textAry.select{|x| x[1].to_i >= item['entryID']}.first(50).map{|x| x[0]}.join("\n\n")
          keyPos = [item['keyPos'][0] + preText.length + 2,item['keyPos'][1]]
          @currentDispItem = [item['path']]
          @concContextView.setString(preText + "\n\n" + restText)
        db.close
      when 2
      	db.open
          textAry = []
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            textAry << [results.resultDictionary['text'],results.resultDictionary['id']]
          end
          preText = textAry.select{|x| x[1].to_i < item['entryID']}.last(50).map{|x| x[0]}.join("\n\n")
          restText = textAry.select{|x| x[1].to_i >= item['entryID']}.first(50).map{|x| x[0]}.join("\n\n")
          keyPos = [item['keyPos'][0] + preText.length + 2,item['keyPos'][1]]
          @currentDispItem = [item['path']]
          @concContextView.setString(preText + "\n\n" + restText)
          results.close
        db.close          
      end
    when 4
      @concContextView.setString("")
      db = SQLite3::Database.new(item['dbPath'])
      text = ""
      db.execute("SELECT text FROM full_text_data WHERE file_id == ?",[item['fileID']]) do |row|
        text = row[:text]
        #text = NSMutableString.alloc.initWithData(row[:text],encoding:NSUTF8StringEncoding)
      end
      @currentDispItem = [item['path']]
      keyPos = item['keyPos']
      @concContextView.setString(text)
    else
      case NSApp.delegate.currentConcScope
      when 1
        if [item['path'],item['encoding']] != @currentDispItem #|| @currentDispItem.nil?
          @concContextView.setString("")
          tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
          contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
          @currentDispItem = [item['path'],item['encoding']]
          @concContextView.setString(contentText)
        end
        keyPos = item['keyPos']
      when 0
        if [item['path'],item['encoding']] != @currentDispItem #|| @currentDispItem.nil?
          @concContextView.setString("")
          tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
          contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
          contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
          keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
          @currentDispItem = [item['path'],item['encoding']]
          @concContextView.setString(contentText)
        else
          contentText = @concContextView.string
          contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
          keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        end
      when 2
        @concContextView.setString("")
        tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
        contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
        contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
        keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        @currentDispItem = [item['path'],item['encoding']]
        @concContextView.setString(contentText)
      end
    end
    @concContextView.setTextColor(NSColor.blackColor)
    @concContextView.setFont(NSFont.fontWithName("Lucida Grande", size: Defaults['concContextViewFontSize']))
    @concContextView.setTextColor(NSColor.redColor, range: keyPos)
    @concContextView.setFont(NSFont.fontWithName("Lucida Grande Bold", size: Defaults['concContextViewFontSize']), range: keyPos)
    @concContextView.scrollRangeToVisible(keyPos)
  end

  
  
end