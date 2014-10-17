
class WordCount
  extend IB

  outlet :mainWindow
  outlet :mainTab
  outlet :wcLeftAryCtl
  outlet :wcRightAryCtl
  outlet :appInfoObjCtl
  outlet :wcLeftTable
  outlet :wcRightTable
  outlet :fileController
  outlet :concController
  
  outlet :currentFileListAry
  outlet :corpusListAry
  outlet :dbListAry
  outlet :selectedCorpusAryCtl
  outlet :selectedDatabaseAryCtl
  
  
  attr_accessor :wcChoice, :wcSortChoice, :wcAryCtl, :wcTable, :wcLabel, :wcEndTime
  attr_accessor :wcSearchWord, :wcTypes, :wcTokens, :wcFileNum, :wcResultInfo, :wcGapCheck
  

  def awakeFromNib
    @wcChoice = ['wcChoiceL','wcChoiceR']
    @wcSortChoice = ['wcSortChoiceL','wcSortChoiceR']
    @wcAryCtl = [@wcLeftAryCtl, @wcRightAryCtl]
    @wcTable = [@wcLeftTable, @wcRightTable]
    @wcLabel = ['Words','2-grams','3-grams','4-grams','5-grams']
    @wcSearchWord = ['wcSearchWordL','wcSearchWordR']
    @wcTypes = ['wcTypesL','wcTypesR']
    @wcTokens = ['wcTokensL','wcTokensR']
    @wcFileNum = ['wcFileNumL','wcFileNumR']
    @wcResultInfo = ['wcResultInfoL','wcResultInfoR']
    @wcGapCheck = ['wcGapL','wcGapR']
    @wcGapLDetailCheck = ['wcGapLDetail','wcGapRDetail']
    @wcCDSelection = [['wcLeftCorpusSelection','wcRightCorpusSelection'],['wcLeftDatabaseSelection','wcRightDatabaseSelection']]
    @wcLeftTable.tableColumnWithIdentifier('lemma').setHidden(true)
    @wcRightTable.tableColumnWithIdentifier('lemma').setHidden(true)
    @wcLeftTable.tableColumnWithIdentifier('contentWords').setHidden(true)
    @wcRightTable.tableColumnWithIdentifier('contentWords').setHidden(true)
    @wcLeftTable.tableColumnWithIdentifier('stats').setHidden(true)
    @wcRightTable.tableColumnWithIdentifier('stats').setHidden(true)
    @wcLeftTable.tableColumnWithIdentifier('inCorpus').setHidden(true)
    @wcRightTable.tableColumnWithIdentifier('inCorpus').setHidden(true)
    @wcLeftTable.tableColumnWithIdentifier('word').setWidth(200)
    @wcRightTable.tableColumnWithIdentifier('word').setWidth(200)
  end

  def countWords(sender)
    
    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0 && @fileController.currentFileListAry.arrangedObjects.length == 0
      alert = NSAlert.alertWithMessageText("No file to process on the File Table.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please add at least one file to the File Table.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 0 && NSApp.delegate.inputText.string.length == 0
      alert = NSAlert.alertWithMessageText("Input text is empty.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please copy/paste the text to analyze in the File View.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    elsif Defaults['corpusMode'] == 1 && @fileController.cdListAry[Defaults['mode']].arrangedObjects.select{|x| x['check']}.length == 0
      alert = NSAlert.alertWithMessageText("No #{@fileController.cdLabel[Defaults['mode']]} is selected.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please select at least one #{@fileController.cdLabel[Defaults['mode']]} on the Table.")

      alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
        @mainTab.selectTabViewItemAtIndex(0)
      })
      return
    end
    
    t = Time.now
    
    NSApp.delegate.progressBar.setIndeterminate(true)
    NSApp.delegate.progressBar.startAnimation(nil)

    if sender.tag == 0
      NSApp.delegate.currentWL = nil
    end
    
    if sender.tag == 0
      ['llStat','chiStat','diceStat','csmStat','pmiStat','cosStat'].each do |id|
        @wcLeftTable.removeTableColumn(@wcLeftTable.tableColumnWithIdentifier(id)) if @wcLeftTable.tableColumnWithIdentifier(id)
      end
    end
    
    @wcTable[sender.tag].tableColumnWithIdentifier('lemma').setHidden(!Defaults['lemmaCheck'])
    #@wcTable[sender.tag].tableColumnWithIdentifier('inFile').setHidden(Defaults['mode'] != 0)
    @wcTable[sender.tag].tableColumnWithIdentifier('inCorpus').setHidden(true)
    @wcTable[sender.tag].tableColumnWithIdentifier('contentWords').setHidden(!(@appInfoObjCtl.content[@wcChoice[sender.tag]] > 0 && @appInfoObjCtl.content[@wcGapCheck[sender.tag]] && @appInfoObjCtl.content[@wcGapLDetailCheck[sender.tag]]))
    
    @wcAryCtl[sender.tag].setSortDescriptors(nil)
    @wcAryCtl[sender.tag].setFilterPredicate(nil)
    @wcAryCtl[sender.tag].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@wcAryCtl[sender.tag].arrangedObjects.length]))

    @nGramSeparator = (Defaults['lemmaCheck'] || Defaults['spVarCheck']) ? "\t" : " "
    
    Dispatch::Queue.concurrent.async{
    
      case @appInfoObjCtl.content[@wcChoice[sender.tag]]
      when 0
        if !@appInfoObjCtl.content[@wcSearchWord[sender.tag]].nil? && @appInfoObjCtl.content[@wcSearchWord[sender.tag]].strip != ""
          wcResult = self.searchWord(sender.tag,@appInfoObjCtl.content[@wcSearchWord[sender.tag]])
        else
          wcResult = self.createWordList(sender.tag)
        end
      else
        if @appInfoObjCtl.content[@wcGapCheck[sender.tag]]
          wcResult = self.createGapNgramList(sender.tag)
        else
          #@wcTable[sender.tag].tableColumnWithIdentifier('inFile').setHidden(true)
          wcResult = self.createNgramList(sender.tag)
        end
      end

      NSApp.delegate.progressBar.setIndeterminate(true)
      NSApp.delegate.progressBar.startAnimation(nil)

      totalTypes = wcResult[0].length

      @appInfoObjCtl.content[@wcTypes[sender.tag]] = totalTypes
      @appInfoObjCtl.content[@wcTokens[sender.tag]] = wcResult[1]
      @appInfoObjCtl.content[@wcFileNum[sender.tag]] = wcResult[2]
      nf = NSNumberFormatter.alloc.init.setFormatterBehavior(NSNumberFormatterBehavior10_4).setNumberStyle(NSNumberFormatterDecimalStyle)
      @appInfoObjCtl.content[@wcResultInfo[sender.tag]] = "#{nf.stringFromNumber(totalTypes)} types #{nf.stringFromNumber(wcResult[1])} tokens in #{nf.stringFromNumber(wcResult[2])} files"
    
      if Defaults['lemmaCheck'] && @appInfoObjCtl.content[@wcChoice[sender.tag]] == 0
        @wcTable[sender.tag].tableColumnWithIdentifier('lemma').setHidden(false)
        lemmas = ListItemProcesses.new
        lemmaResult = lemmas.lemmaApplication(wcResult[0],wcResult[3],"wc")
        wcResult[0] = lemmaResult[0]
        lemmaList = lemmaResult[1]
        wcResult[3] = lemmaResult[2]
      end

      wcOutAry = Array.new
      propFlag = 0
      listOrder = 0
      currentFreq = 0
      if !Defaults['wchStopWordCheck']
        case @appInfoObjCtl.content[@wcChoice[sender.tag]]
        when 0
          if sender.tag == 0
            NSApp.delegate.currentWL = wcResult[0]
          end
          #wcResult[0].delete_if{|x,y| y < 2}
          case Defaults['corpusMode']
          when 0
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              next if item[1] <= Defaults['wordMinNum']            
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0]
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          when 1
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              next if item[1] <= Defaults['wordMinNum']            
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0]
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              wcOut['inCorpus'] = wcResult[4][item[0]].length
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          end      
        else
          wcResult[0].delete_if{|x,y| y < Defaults['ngramMinNum']}
          case Defaults['corpusMode']
          when 0
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0].join(" ")
              #wcOut['word'] = item[0]
              #wcOut['word'] = item[0].gsub("\t"," ")
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              #wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].join(" ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              #wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].gsub("\t"," ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              if @appInfoObjCtl.content[@wcGapCheck[sender.tag]] && @appInfoObjCtl.content[@wcGapLDetailCheck[sender.tag]]
                contWList = wcResult[5][item[0]].sort_by{|x,y| [-y,x]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ")
                wcOut['contentWords'] = contWList
              end
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          when 1
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0].join(" ")
              #wcOut['word'] = item[0]
              #wcOut['word'] = item[0].gsub("\t"," ")
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              #wcOut['inCorpus'] = wcResult[4][item[0]].length
              #wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].join(" ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              #wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].gsub("\t"," ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              if @appInfoObjCtl.content[@wcGapCheck[sender.tag]] && @appInfoObjCtl.content[@wcGapLDetailCheck[sender.tag]]
                contWList = wcResult[5][item[0]].sort_by{|x,y| [-y,x]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ")
                wcOut['contentWords'] = contWList
              end
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          end
        end
      else
        stopWReg = Regexp.new('\b(?:'+NSApp.delegate.stopWords+')\b',Regexp::IGNORECASE)
        case @appInfoObjCtl.content[@wcChoice[sender.tag]]
        when 0
          if sender.tag == 0
            NSApp.delegate.currentWL = wcResult[0]
          end
          #wcResult[0].delete_if{|x,y| y < 2}
          case Defaults['corpusMode']
          when 0
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              next if item[0].match(stopWReg) || item[1] <= Defaults['wordMinNum']            
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0]
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          when 1
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              next if item[0].match(stopWReg) || item[1] <= Defaults['wordMinNum']            
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0]
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              wcOut['inCorpus'] = wcResult[4][item[0]].length
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          end      
        else
          wcResult[0].delete_if{|x,y| y < Defaults['ngramMinNum']}
          case Defaults['corpusMode']
          when 0
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              next if item[0].match(stopWReg)
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0].join(" ")
              #wcOut['word'] = item[0]
              #wcOut['word'] = item[0].gsub("\t"," ")
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              #wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].gsub("\t"," ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              if @appInfoObjCtl.content[@wcGapCheck[sender.tag]] && @appInfoObjCtl.content[@wcGapLDetailCheck[sender.tag]]
                contWList = wcResult[5][item[0]].sort_by{|x,y| [-y,x]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ")
                wcOut['contentWords'] = contWList
              end
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          when 1
            wcResult[0].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|      
              next if item[0].match(stopWReg)
              wcOut = Hash.new
              listOrder = idx + 1 if currentFreq != item[1]
              wcOut['word'] = item[0].join(" ")
              #wcOut['word'] = item[0]
              #wcOut['word'] = item[0].gsub("\t"," ")
              wcOut['rank'] = listOrder
              wcOut['freq'] = item[1]
              #wcOut['inFile'] = wcResult[3][item[0]].length
              propFlag = 1 if propFlag == 0 && item[1]/wcResult[1].to_f < 0.0001
              wcOut['prop'] = item[1]/wcResult[1].to_f if propFlag == 0
              #wcOut['inCorpus'] = wcResult[4][item[0]].length
              wcOut['lemma'] = lemmaList[item[0]].sort_by{|x| -x[1]}.map{|x| "#{x[0].gsub("\t"," ")} (#{x[1]})"}.join(", ") if Defaults['lemmaCheck'] && lemmaList[item[0]].length > 1
              if @appInfoObjCtl.content[@wcGapCheck[sender.tag]] && @appInfoObjCtl.content[@wcGapLDetailCheck[sender.tag]]
                contWList = wcResult[5][item[0]].sort_by{|x,y| [-y,x]}.map{|x| "#{x[0]} (#{x[1]})"}.join(", ")
                wcOut['contentWords'] = contWList
              end
              wcOutAry << wcOut
              currentFreq = item[1]
            end
          end
        end      
      end
      Dispatch::Queue.main.async{
      
        @wcAryCtl[sender.tag].addObjects(wcOutAry)
    
        NSApp.delegate.progressBar.stopAnimation(nil)
    
        @wcTable[sender.tag].tableColumnWithIdentifier('word').headerCell.setStringValue(@wcLabel[@appInfoObjCtl.content[@wcChoice[sender.tag]]].to_s)
    
        NSApp.delegate.currentWCMode[sender.tag] = [Defaults['mode'],Defaults['corpusMode']]
    
        @appInfoObjCtl.content['timer'] = Time.now - t
        @wcEndTime = Time.now
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
  
  
  def createWordList(tableID)
    tagProcessItems = @fileController.tagPreparation if Defaults['tagModeEnabled']
    numReg = /\b\d+(?:.\d+)*\b/
    wordReg = Regexp.new(WildWordProcess.new("wc").wildWord,Regexp::IGNORECASE)
    wordHash = Hash.new(0)
    foundFile = Hash.new{|foundFile,word| foundFile[word] = Hash.new}
    foundCorpus = Hash.new{|foundCorpus,word| foundCorpus[word] = Hash.new}
    totalFreq = 0
    totalFiles = 0
    @notFoundFiles = Array.new
    case Defaults['mode']
    when 0
      case Defaults['corpusMode']
      when 0
        filesToProcess = @fileController.currentFileListAry.arrangedObjects.length
        if filesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(filesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        NSApp.delegate.currentWCCDs[tableID] = "Simple - Files"
        @fileController.currentFileListAry.arrangedObjects.each_with_index do |item,idx|
          if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
            @notFoundFiles << item['path']
            next
          end
          autorelease_pool {        
            inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
            inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
            words = inText.scan(wordReg)
            words.each do |word|
            #inText.scan(wordReg) do |word|
              wordHash[word] += 1
              foundFile[word][idx] = 1
              totalFreq += 1
            end
            totalFiles += 1
          }
          NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 1
        end
      when 1
        filesToProcess = Array.new
        if @appInfoObjCtl.content[@wcCDSelection[0][tableID]] == 0
          NSApp.delegate.currentWCCDs[tableID] = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")
          @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            filesToProcess << NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
          end
        else
          NSApp.delegate.currentWCCDs[tableID] = @fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['name']
          filesToProcess << NSMutableArray.arrayWithContentsOfFile(@fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
        end
        
        totalFilesToProcess = filesToProcess.inject(0){|num,item| num + item.length}

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        @wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
        filesToProcess.each_with_index do |files,idx|
          files.each do |item|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
              inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
              #words = inText.scan(wordReg)
              #words.each do |word|
              inText.scan(wordReg) do |word|
                wordHash[word] += 1
                foundFile[word][totalFiles] = 1
                foundCorpus[word][idx] = 1
                totalFreq += 1
              end
              totalFiles += 1
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      end
    when 1
      case Defaults['corpusMode']
      when 0
        NSApp.delegate.currentWCCDs[tableID] = "Simple - Text"
        inText = NSApp.delegate.inputText.string.dup
        inText.downcase! if !Defaults['searchWordCaseSensitivity']
        inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
        inText = @fileController.tagApplication(inText,tagProcessItems,"wc","current") if Defaults['tagModeEnabled']
        #words = inText.scan(wordReg)
        #words.each do |word|
        inText.scan(wordReg) do |word|
          wordHash[word] += 1
          totalFreq += 1
        end
        totalFiles += 1
      when 1
        filesToProcess = Array.new
        totalFilesToProcess = 0
        if @appInfoObjCtl.content[@wcCDSelection[1][tableID]] == 0
          @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            fileIDs = Array.new
            autorelease_pool {        
              db = FMDatabase.databaseWithPath(corpusItem['path'])
              db.open
                results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
                while results.next
                  fileIDs << results.resultDictionary['file_id']
                end
                totalFilesToProcess += fileIDs.length
                filesToProcess << [corpusItem['path'],fileIDs]
                results.close            
              db.close
            }
          end
        else
          path = @fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[1][tableID]]]['path']
          autorelease_pool {        
            db = FMDatabase.databaseWithPath(corpusItem['path'])
            db.open
              results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
              while results.next
                fileIDs << results.resultDictionary['file_id']
              end
              totalFilesToProcess = fileIDs.length
              filesToProcess << [corpusItem['path'],fileIDs]
              results.close            
            db.close
          }
        end

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end

        NSApp.delegate.currentWCCDs[tableID] = filesToProcess.map{|x| File.basename(x[0],".*")}.join(", ")
        @wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1

        filesToProcess.each_with_index do |ccdb,fileIDs|
          ccdb[1].each do |fileID|
            autorelease_pool {        
              db = FMDatabase.databaseWithPath(ccdb[0])
              db.open
                textAry = Array.new
                results = db.executeQuery("SELECT text FROM conc_data where file_id == ? order by id",fileID)
                while results.next
                  textAry << results.resultDictionary['text'].mutableCopy
                end
                inText = textAry.join("\n\n").downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                inText.scan(wordReg) do |word|
                  wordHash[word] += 1
                  foundFile[word][fileID] = 1
                  foundCorpus[word][fileID] = 1 if filesToProcess.length > 1
                  totalFreq += 1
                end
                totalFiles += 1
                results.close
              db.close
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      end
    end
    return [wordHash,totalFreq,totalFiles,foundFile,foundCorpus]
  end
  
  
  def createNgramList(tableID)
    
    n = @appInfoObjCtl.content[@wcChoice[tableID]]
    tagProcessItems = @fileController.tagPreparation if Defaults['tagModeEnabled']
    numReg = /\b\d+(?:.\d+)*\b/
    wordReg = Regexp.new(WildWordProcess.new("wc").wildWord,Regexp::IGNORECASE)
    wordHash = Hash.new(0)
    foundFile = Hash.new{|foundFile,word| foundFile[word] = Hash.new}
    foundCorpus = Hash.new{|foundCorpus,word| foundCorpus[word] = Hash.new}
    totalFreq = 0
    totalFiles = 0
    @notFoundFiles = Array.new
    case Defaults['mode']
    when 0
      case Defaults['corpusMode']
      when 0
        filesToProcess = @fileController.currentFileListAry.arrangedObjects.length
        if filesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(filesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        NSApp.delegate.currentWCCDs[tableID] = "Simple - Files"
        
        case Defaults['scopeOfContextChoice']
        when 0,2
          pp = 1
          @fileController.currentFileListAry.arrangedObjects.each_with_index do |item,idx|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
              inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
              #inText.lines.each do |parag|
              inText.split(/\r*\n|\r/).each do |parag|
                #next if (words = parag.strip.scan(wordReg)).length < (n + 1)
                words = parag.strip.scan(wordReg)
                #wordsLength = words.length
                #next if wordsLength - n < 0
                (words.length - n).times do |i|
                  wordHash[words[i..i+n]] += 1
                  #wordHash[words[i..i+n].join(" ")] += 1
                  #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
                  foundFile[words[i..i+n]][totalFiles] = 1
                  totalFreq += 1
                end
              end
              totalFiles += 1
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 1
          end
        when 1
          @fileController.currentFileListAry.arrangedObjects.each_with_index do |item,idx|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
              inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
              words = inText.scan(wordReg)
              (words.length - n).times do |i|
                wordHash[words[i..i+n]] += 1
                #wordHash[words[i..i+n].join(" ")] += 1
                #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
                foundFile[words[i..i+n]][totalFiles] = 1
                totalFreq += 1
              end
              totalFiles += 1
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 1
          end
        end
      when 1
        filesToProcess = Array.new
        if @appInfoObjCtl.content[@wcCDSelection[0][tableID]] == 0
          @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            NSApp.delegate.currentWCCDs[tableID] = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")
            filesToProcess << NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
          end
        else
          NSApp.delegate.currentWCCDs[tableID] = @fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['name']
          filesToProcess << NSMutableArray.arrayWithContentsOfFile(@fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
        end
        
        totalFilesToProcess = filesToProcess.inject(0){|num,item| num + item.length}

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        #@wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
        case Defaults['scopeOfContextChoice']
        when 0,2
          filesToProcess.each_with_index do |files,idx|
            files.each_with_index do |item,fidx|
              autorelease_pool {        
                inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                inText.lines.each do |parag|
                  next if (words = parag.strip.scan(wordReg)).length < (n + 1)
                  (words.length - n).times do |i|
                    wordHash[words[i..i+n]] += 1
                    #wordHash[words[i..i+n].join(" ")] += 1
                    #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
                    foundFile[words[i..i+n]][totalFiles] = 1
                    totalFreq += 1
                  end
                end
                totalFiles += 1
              }
              NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
            end
          end
        when 1
          filesToProcess.each_with_index do |files,idx|
            files.each_with_index do |item|
              autorelease_pool {        
                inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                words = inText.scan(wordReg)
                (words.length - n).times do |i|
                  wordHash[words[i..i+n]] += 1
                  #wordHash[words[i..i+n].join(" ")] += 1
                  #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
                  foundFile[words[i..i+n]][totalFiles] = 1
                  totalFreq += 1
                end
                totalFiles += 1
                NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
              }
            end
          end
        end
      end
    when 1
      case Defaults['corpusMode']
      when 0
        NSApp.delegate.currentWCCDs[tableID] = "Simple - Text"
        inText = NSApp.delegate.inputText.string
        inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
        inText = @fileController.tagApplication(inText,tagProcessItems,"wc","current") if Defaults['tagModeEnabled']
        
        case Defaults['scopeOfContextChoice']
        when 0,2
          inText.lines.each do |parag|
            next if (words = parag.strip.scan(wordReg)).length < (n + 1)
            (words.length - n).times do |i|
              wordHash[words[i..i+n]] += 1
              #wordHash[words[i..i+n].join(" ")] += 1
              #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
              #foundFile[words[i..n]][idx] = 1
              totalFreq += 1
            end
          end
        when 1
          words = inText.scan(wordReg)
          (words.length - n).times do |i|
            wordHash[words[i..i+n]] += 1
            #wordHash[words[i..i+n].join(" ")] += 1
            #wordHash[words[i..i+n].join(@nGramSeparator)] += 1
            #foundFile[words[i..n]][idx] = 1
            totalFreq += 1
          end
        end
        totalFiles += 1
      when 1
        filesToProcess = Array.new
        totalFilesToProcess = 0
        if @appInfoObjCtl.content[@wcCDSelection[1][tableID]] == 0
          @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            fileIDs = Array.new
            db = FMDatabase.databaseWithPath(corpusItem['path'])
            db.open
              results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
              while results.next
                fileIDs << results.resultDictionary['file_id']
              end
              totalFilesToProcess += fileIDs.length
              filesToProcess << [corpusItem['path'],fileIDs]
              results.close            
            db.close
          end
        else
          path = @fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[1][tableID]]]['path']
          db = FMDatabase.databaseWithPath(corpusItem['path'])
          db.open
            results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
            while results.next
              fileIDs << results.resultDictionary['file_id']
            end
            totalFilesToProcess = fileIDs.length
            filesToProcess << [corpusItem['path'],fileIDs]
            results.close            
          db.close
        end

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end

        NSApp.delegate.currentWCCDs[tableID] = filesToProcess.map{|x| File.basename(x[0],".*")}.join(", ")
        
        @wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
        
        filesToProcess.each_with_index do |ccdb,fileIDs|
          ccdb[1].each do |fileID|
            autorelease_pool {        
              db = FMDatabase.databaseWithPath(ccdb[0])
              db.open
                textAry = Array.new
                results = db.executeQuery("SELECT text FROM conc_data where file_id == ? order by id",fileID)
                while results.next
                  textAry << results.resultDictionary['text'].mutableCopy
                end
                inText = textAry.join("\n\n").downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                words = inText.scan(wordReg)
                (words.length - n).times do |i|
                  wordHash[words[i..i+n]] += 1
                  foundFile[words[i..n]][totalFiles] = 1
                  foundCorpus[words[i..n]][fileID] = 1 if filesToProcess.length > 1
                  totalFreq += 1
                end
                totalFiles += 1
                results.close
              db.close     
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      end
    end    
    return [wordHash,totalFreq,totalFiles,foundFile,foundCorpus]
  end
  
  
  def searchWord(tableID,searchWord)
    wordReg = MyString.new(searchWord).concRegConversion(WildWordProcess.new("conc"),["wc",tableID])
    tagProcessItems = @fileController.tagPreparation if Defaults['tagModeEnabled']
    wordHash = Hash.new(0)
    foundFile = Hash.new{|foundFile,word| foundFile[word] = Hash.new}
    foundCorpus = Hash.new{|foundCorpus,word| foundCorpus[word] = Hash.new}
    totalFreq = 0
    totalFiles = 0
    @notFoundFiles = Array.new
    #case @appInfoObjCtl.content["wcBWNonCharCleanCheck#{sender.tag}"]
    #when false,nil
    #end
    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0
      filesToProcess = @fileController.currentFileListAry.arrangedObjects
      if filesToProcess.length > 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(@fileController.currentFileListAry.arrangedObjects.length)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end
      NSApp.delegate.currentWCCDs[tableID] = "Simple - Files"
      
      filesToProcess.each_with_index do |item,idx|
        if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
          @notFoundFiles << item['path']
          next
        end
        
        inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,wordReg)
        inText.downcase! if !Defaults['searchWordCaseSensitivity']
        inText.scan(wordReg) do
          wordHash[$&] += 1
          foundFile[$&][idx] = 1
          totalFreq += 1
        end
        totalFiles += 1
        NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess.length > 1
      end
      
      if filesToProcess.length > 1
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
    elsif Defaults['mode'] == 0 && Defaults['corpusMode'] == 1
      filesToProcess = Array.new
      if @appInfoObjCtl.content[@wcCDSelection[0][tableID]] == 0
        @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          NSApp.delegate.currentWCCDs[tableID] = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")
          filesToProcess << NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
        end
      else
        NSApp.delegate.currentWCCDs[tableID] = @fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['name']
        filesToProcess << NSMutableArray.arrayWithContentsOfFile(@fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
      end
      
      totalFilesToProcess = filesToProcess.inject(0){|num,item| num + item.length}
      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end
      @wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
      filesToProcess.each_with_index do |files,idx|
        files.each do |item|
          if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
            @notFoundFiles << item['path']
            next
          end
          autorelease_pool {        
            inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,wordReg)
            inText.downcase! if !Defaults['searchWordCaseSensitivity']
            inText.scan(wordReg) do
              wordHash[$&] += 1
              foundFile[$&][totalFiles] = 1
              foundCorpus[$&][idx] = 1
              totalFreq += 1
            end
            totalFiles += 1
          }
          NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
        end
      end
      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 0
      NSApp.delegate.currentWCCDs[tableID] = "Simple - Text"
      inText = NSApp.delegate.inputText.string.dup
      inText.downcase! if !Defaults['searchWordCaseSensitivity']
      inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
      inText = @fileController.tagApplication(inText,tagProcessItems,"concord","current") if Defaults['tagModeEnabled']
      
      inText.scan(wordReg) do
        wordHash[$&] += 1
        totalFreq += 1
      end
      totalFiles += 1
    else
      currentFile = []
      filesToProcess = Array.new
      totalFilesToProcess = 0
      if @appInfoObjCtl.content[@wcCDSelection[1][tableID]] == 0
        @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
          fileIDs = Array.new
          db = FMDatabase.databaseWithPath(corpusItem['path'])
          db.open
            results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
            while results.next
              fileIDs << results.resultDictionary['file_id']
            end
            totalFilesToProcess += fileIDs.length
            filesToProcess << [corpusItem['path'],fileIDs]
            results.close            
          db.close
        end
      else
        path = @fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[1][tableID]]]['path']
        db = FMDatabase.databaseWithPath(corpusItem['path'])
        db.open
          results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
          while results.next
            fileIDs << results.resultDictionary['file_id']
          end
          totalFilesToProcess = fileIDs.length
          filesToProcess << [corpusItem['path'],fileIDs]
          results.close            
        db.close
      end

      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end

      NSApp.delegate.currentWCCDs[tableID] = filesToProcess.map{|x| File.basename(x[0],".*")}.join(", ")
      @wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1

      filesToProcess.each_with_index do |ccdb,fileIDs|
        ccdb[1].each do |fileID|
          autorelease_pool {        
            db = FMDatabase.databaseWithPath(ccdb[0])
            db.open
              textAry = Array.new
              results = db.executeQuery("SELECT text FROM conc_data where file_id == ? order by id",fileID)
              while results.next
                textAry << results.resultDictionary['text'].mutableCopy
              end
              inText = textAry.join("\n\n")
        	    inText.downcase! if !Defaults['searchWordCaseSensitivity']
              inText.scan(wordReg) do
                wordHash[$&] += 1
                foundFile[$&][totalFiles] = 1
                foundCorpus[$&][idx] = 1
                totalFreq += 1
              end
              totalFiles += 1 if currentFile != [idx,fileID]
              currentFile = [idx,fileID]
              results.close
            db.close
          }
          NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
        end
      end
    end
    return [wordHash,totalFreq,totalFiles,foundFile,foundCorpus]    
  end
  
  
  def createGapNgramList(tableID)
    n = @appInfoObjCtl.content[@wcChoice[tableID]]
    tagProcessItems = @fileController.tagPreparation if Defaults['tagModeEnabled']
    numReg = /\b\d+(?:.\d+)*\b/
    wordReg = Regexp.new(WildWordProcess.new("wc").wildWord,Regexp::IGNORECASE)
    wordHash = Hash.new(0)
    foundFile = Hash.new{|foundFile,word| foundFile[word] = Hash.new}
    foundCorpus = Hash.new{|foundCorpus,word| foundCorpus[word] = Hash.new}
    gapItems = Hash.new{|gapItems,word| gapItems[word] = Hash.new(0)}
    totalFreq = 0
    totalFiles = 0
    @notFoundFiles = Array.new
    case Defaults['mode']
    when 0
      case Defaults['corpusMode']
      when 0
        filesToProcess = @fileController.currentFileListAry.arrangedObjects.length
        if filesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(filesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        NSApp.delegate.currentWCCDs[tableID] = "Simple - Files"
        
        case Defaults['scopeOfContextChoice']
        when 0,2
          @fileController.currentFileListAry.arrangedObjects.each_with_index do |item,idx|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
              inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
              inText.lines.each do |parag|
                next if (words = parag.strip.scan(wordReg)).length < (n + 1)
                (words.length - n).times do |i|
                  n.times do |j|
                    ngram = words[i..i+n]
                    ngram[j] = "*"
                    #wordHash[ngram.join(" ")] += 1
                    wordHash[ngram.join(@nGramSeparator)] += 1
                    foundFile[ngram][idx] = 1
                    gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                    totalFreq += 1                  
                  end
                end
              end
              totalFiles += 1
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 1
          end
        when 1
          @fileController.currentFileListAry.arrangedObjects.each_with_index do |item,idx|
            if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
              @notFoundFiles << item['path']
              next
            end
            autorelease_pool {        
              inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
              inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
              words = inText.scan(wordReg)
              (words.length - n).times do |i|
                n.times do |j|
                  ngram = words[i..i+n]
                  ngram[j] = "*"
                  #wordHash[ngram.join(" ")] += 1
                  wordHash[ngram.join(@nGramSeparator)] += 1
                  foundFile[ngram][idx] = 1
                  gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                  totalFreq += 1                  
                end
              end
              totalFiles += 1
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 1
          end
        end
      when 1
        filesToProcess = Array.new
        if @appInfoObjCtl.content[@wcCDSelection[0][tableID]] == 0
          @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            NSApp.delegate.currentWCCDs[tableID] = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")
            filesToProcess << NSMutableArray.arrayWithContentsOfFile(corpusItem['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
          end
        else
          NSApp.delegate.currentWCCDs[tableID] = @fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['name']
          filesToProcess << NSMutableArray.arrayWithContentsOfFile(@fileController.selectedCorpusAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[0][tableID]]]['path']).map{|x| {'path' => x['path'], 'encoding' => x['encoding']}}
        end
        
        totalFilesToProcess = filesToProcess.inject(0){|num,item| num + item.length}

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        #@wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
        case Defaults['scopeOfContextChoice']
        when 0,2
          filesToProcess.each_with_index do |files,idx|
            files.each do |item|
              autorelease_pool {        
                inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                inText.lines.each do |parag|
                  next if (words = parag.strip.scan(wordReg)).length < (n + 1)
                  (words.length - n).times do |i|
                    n.times do |j|
                      ngram = words[i..i+n]
                      ngram[j] = "*"
                      wordHash[ngram] += 1
                      #wordHash[ngram.join(" ")] += 1
                      #wordHash[ngram.join(@nGramSeparator)] += 1
                      gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                      foundFile[ngram][totalFiles] = 1
                      totalFreq += 1                  
                    end
                  end
                end
                totalFiles += 1
              }
              NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
            end
          end
        when 1
          filesToProcess.each_with_index do |files,idx|
            files.each do |item|
              autorelease_pool {        
                inText = @fileController.readFileContents(item['path'],item['encoding'],"wc",tagProcessItems,nil).downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                words = inText.scan(wordReg)
                (words.length - n).times do |i|
                  n.times do |j|
                    ngram = words[i..i+n]
                    ngram[j] = "*"
                    wordHash[ngram] += 1
                    #wordHash[ngram.join(" ")] += 1
                    #wordHash[ngram.join(@nGramSeparator)] += 1
                    gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                    foundFile[ngram][idx] = 1
                    totalFreq += 1                  
                  end
                end
                totalFiles += 1
              }
              NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
            end
          end
        end
      end
    when 1
      case Defaults['corpusMode']
      when 0
        inText = NSApp.delegate.inputText.string
        inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
        inText = @fileController.tagApplication(inText,tagProcessItems,"wc","current") if Defaults['tagModeEnabled']
        case Defaults['scopeOfContextChoice']
        when 0,2
          inText.lines.each do |parag|
            next if (words = parag.strip.scan(wordReg)).length < (n + 1)
            (words.length - n).times do |i|
              n.times do |j|
                ngram = words[i..i+n]
                ngram[j] = "*"
                wordHash[ngram] += 1
                #wordHash[ngram.join(" ")] += 1
                #wordHash[ngram.join(@nGramSeparator)] += 1
                gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                foundFile[ngram][idx] = 1
                totalFreq += 1                  
              end
            end
          end
        when 1
          words = inText.scan(wordReg)
          (words.length - n).times do |i|
            n.times do |j|
              ngram = words[i..i+n]
              ngram[j] = "*"
              wordHash[ngram] += 1
              #wordHash[ngram.join(" ")] += 1
              #wordHash[ngram.join(@nGramSeparator)] += 1
              gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
              foundFile[ngram][idx] = 1
              totalFreq += 1                  
            end
          end
        end
        totalFiles += 1
      when 1
        filesToProcess = Array.new
        totalFilesToProcess = 0
        if @appInfoObjCtl.content[@wcCDSelection[1][tableID]] == 0
          @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
            fileIDs = Array.new
            db = FMDatabase.databaseWithPath(corpusItem['path'])
            db.open
              results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
              while results.next
                fileIDs << results.resultDictionary['file_id']
              end
              totalFilesToProcess += fileIDs.length
              filesToProcess << [corpusItem['path'],fileIDs]
              results.close            
            db.close
          end
        else
          path = @fileController.selectedDatabaseAryCtl.arrangedObjects[@appInfoObjCtl.content[@wcCDSelection[1][tableID]]]['path']
          db = FMDatabase.databaseWithPath(corpusItem['path'])
          db.open
            results = db.executeQuery("SELECT DISTINCT file_id, encoding FROM conc_data")
            while results.next
              fileIDs << results.resultDictionary['file_id']
            end
            totalFilesToProcess = fileIDs.length
            filesToProcess << [corpusItem['path'],fileIDs]
            results.close            
          db.close
        end

        if totalFilesToProcess > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        NSApp.delegate.currentWCCDs[tableID] = filesToProcess.map{|x| File.basename(x[0],".*")}.join(", ")
        
        #@wcTable[tableID].tableColumnWithIdentifier('inCorpus').setHidden(false) if filesToProcess.length > 1
        

        filesToProcess.each_with_index do |ccdb,idx|
          ccdb[1].each do |fileID|
            autorelease_pool {        
              db = FMDatabase.databaseWithPath(ccdb[0])
              db.open
                textAry = Array.new
                results = db.executeQuery("SELECT text FROM conc_data where file_id == ? order by id",fileID)
                while results.next
                  textAry << results.resultDictionary['text'].mutableCopy
                end
                inText = textAry.join("\n\n").downcase
                inText.gsub!(numReg,"#") if Defaults['numberHandleChoice'] == 1
                words = inText.scan(wordReg)
                (words.length - n).times do |i|
                  n.times do |j|
                    ngram = words[i..i+n]
                    ngram[j] = "*"
                    wordHash[ngram] += 1
                    foundFile[ngram][totalFiles] = 1
                    gapItems[ngram][words[i+j]] += 1 if @wcGapLDetailCheck[tableID]
                    #foundCorpus[ngram][fileID] = 1 if filesToProcess.length > 1
                    totalFreq += 1                  
                  end
                end
                totalFiles += 1
                results.close
              db.close
            }
            NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          end
        end
      end
    end
    return [wordHash,totalFreq,totalFiles,foundFile,foundCorpus,gapItems]
  end
  
  
  
  def resortList(sender)
    @wcAryCtl[sender.tag].setFilterPredicate(nil)
    
    wcAry = case @appInfoObjCtl.content[@wcSortChoice[sender.tag]]
    when 0
      @wcAryCtl[sender.tag].arrangedObjects.sort_by{|x| x['word'].reverse}
    when 1
      @wcAryCtl[sender.tag].arrangedObjects.sort_by{|x| [-x['word'].length,x['word']]}
    when 2
      @wcAryCtl[sender.tag].arrangedObjects.sort_by{|x| [x['word'].length,x['word']]}
    end
    @wcAryCtl[sender.tag].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@wcAryCtl[sender.tag].arrangedObjects.length]))
    @wcAryCtl[sender.tag].addObjects(wcAry)
  end
  
  
  
  def searchInConcord(sender)
    if @concController.concResultAry.length > 0
      alert = NSAlert.alertWithMessageText("Are you sure you want to search the selected words in Concord?",
                                          defaultButton:"Yes",
                                          alternateButton:nil,
                                          otherButton:"Cancel",
                                          informativeTextWithFormat:"The Concord results on the table will be gone.")
      alert.buttons[1].setKeyEquivalent("\e")
      return if alert.runModal == -1
    end
    
    tableID = sender.menu.title == "WC Menu L" ? 0 : 1
    @appInfoObjCtl.content['concSearchWord'] = @wcAryCtl[tableID].selectedObjects.map{|x| x['word']}.join("/")
    @appInfoObjCtl.content.removeObjectForKey('concContextWord') if !@appInfoObjCtl.content['concContextWord'].nil?
    @appInfoObjCtl.content.removeObjectForKey('concExcludeWord') if Defaults['contextExcludeCheck'] && !@appInfoObjCtl.content['concExcludeWord'].nil?
    @mainTab.selectTabViewItemAtIndex(1)
    @concController.concSearchBtn.setTag(10 + tableID)
    @concController.concSearchBtn.performClick(self)
  end
  
  
  def copySelectedLines(sender)
    pasteBoard = NSPasteboard.pasteboardWithName(NSGeneralPboard)
    pasteBoard.declareTypes([NSStringPboardType],owner:self)
    copyText = ""
    case sender.tag
    when 0,1
      aryCtl = sender.tag == 0 ? @wcAryCtl[0] : @wcAryCtl[1]
      aryCtl.selectedObjects.each do |item|
        formatter = NSNumberFormatter.alloc.init
        formatter.setFormatterBehavior(NSNumberFormatterBehavior10_4)
        formatter.setNumberStyle(NSNumberFormatterPercentStyle)
        formatter.setFormat("#,##0.00%")
        prop = formatter.stringFromNumber(item['prop'])
        copyText += "#{item['rank']}\t#{item['word']}\t#{item['freq']}\t#{prop}\t#{item['inFile']}\t#{item['lemma']}\n"
      end
    when 2,3      
      aryCtl = sender.tag == 2 ? @wcAryCtl[0] : @wcAryCtl[1]
      aryCtl.selectedObjects.each do |item|
        copyText += "#{item['word']}\n"
      end
    end
    pasteBoard.setString(copyText,forType:NSStringPboardType)
    
  end
  
  def calcKeyword(sender)
    NSApp.delegate.progressBar.startAnimation(nil)
    ary = @wcRightAryCtl.arrangedObjects.map{|x| [x['word'],x['freq']] }
    
    wc2Hash = Hash[*ary.flatten]
    wc1Total = @appInfoObjCtl.content[@wcTokens[0]]
    wc2Total = @appInfoObjCtl.content[@wcTokens[1]]
    
    cc = CCStats.new

    case sender.tag
    when 0 # all
      @wcLeftAryCtl.arrangedObjects.each do |item|
        #p "#{item['word']}: #{item['freq']} - #{wc2Hash[item['word']]}"
        llKeyness = cc.llCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        llKeyness = llKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['llStat'] = llKeyness
        chiKeyness = cc.chiSquareCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        chiKeyness = chiKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['chiStat'] = chiKeyness
        diceKeyness = cc.diceScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        diceKeyness = diceKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['diceStat'] = diceKeyness
        csmKeyness = cc.cmsScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        csmKeyness = csmKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['csmStat'] = csmKeyness
        pmiKeyness = cc.pmiScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        pmiKeyness = pmiKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['pmiStat'] = pmiKeyness
        cosKeyness = cc.cosineScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        cosKeyness = cosKeyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['cosStat'] = cosKeyness
      end
      [['LL','llStat'],['Chi-Sq','chiStat'],['Dice','diceStat'],['CSM','csmStat'],['PMI','pmiStat'],['Cosine','cosStat']].each do |item|
        column = NSTableColumn.alloc.initWithIdentifier(item[1])
        column.setWidth(80)
        column.setMinWidth(80)
        headerCell = NSTableHeaderCell.alloc.initTextCell(item[0])
        column.setHeaderCell(headerCell)
        column.setEditable(false)
        textCell = NSTextFieldCell.alloc.init
        textCell.setAlignment(NSRightTextAlignment)
        formatter = MyNumFormatter.alloc.init
        formatter.setFormatterBehavior(NSNumberFormatterBehavior10_4)
        formatter.setNumberStyle(NSNumberFormatterDecimalStyle)
        formatter.setFormat("#,##0.00")
        formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
        textCell.setFormatter(formatter)
        column.setDataCell(textCell)
        column.setSortDescriptorPrototype(NSSortDescriptor.sortDescriptorWithKey(item[1],ascending:true,selector:"compare:"))
        column.bind("value",toObject:@wcLeftAryCtl,withKeyPath:"arrangedObjects.#{item[1]}",options:nil)
        @wcLeftTable.addTableColumn(column)
      end
    when 1 # Log-likelihood
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.llCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("LL")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    when 2 # Chi-square
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.chiSquareCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("Chi-Sq")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    when 3 # Dice coefficient
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.llCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("Dice")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    when 4 # CSM
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.llCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("CSM")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    when 5 # PMI
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.pmiScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("PMI")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    when 6
      @wcLeftAryCtl.arrangedObjects.each do |item|
        keyness = cc.cosineScoreCalc(item['freq'],wc2Hash[item['word']],wc1Total,wc2Total)
        keyness = keyness * -1 if (item['freq'].to_f / wc1Total) < (wc2Hash[item['word']].to_f / wc2Total)
        item['stats'] = keyness
      end
      @wcLeftTable.tableColumnWithIdentifier("stats").headerCell.setStringValue("Cosine")
      @wcLeftTable.tableColumnWithIdentifier("stats").dataCell.formatter.setTextAttributesForNegativeValues({'NSColor' => NSColor.redColor})
    end

    if sender.tag == 0
      
    else
      @wcLeftTable.tableColumnWithIdentifier('stats').setHidden(false) 
    end
    NSApp.delegate.progressBar.stopAnimation(nil)
    @wcLeftTable.reloadData
  end
  

  def showGapWordList(sender)
    @gapContents = WCGapContentsController.new
    @gapContents.items = @wcAryCtl[sender.tag].selectedObjects[0]
    @gapContents.showWindow(self)    
  end
  
  def showLemmaWordList(sender)
    @lemmaContents = WCGapContentsController.new
    @lemmaContents.items = @wcAryCtl[sender.tag].selectedObjects[0]
    @lemmaContents.showWindow(self)    
  end
  
  
end
