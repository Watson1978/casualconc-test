#
#  FileInfo.rb
#  CasualConc
#
#  Created by Yasu on 10/12/22.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

include Math

class FileInfo
  extend IB
  
  outlet :mainWindow
  outlet :mainTab
  outlet :appInfoObjCtl
  outlet :fileController
  outlet :concConctroller
  outlet :fiWLImportChoiceView
  outlet :importKGPanel
  outlet :importKGTable
  outlet :importKGTextPanel
  outlet :importWLText
  outlet :importKGAryCtl
  outlet :importKGText
  outlet :startProcessBtn
  outlet :currentFIType
  outlet :itemOrder
  outlet :groupingPanel
  outlet :groupLabellingPanel
  outlet :groupingAryCtl
  outlet :groupLabelAryCtl
  outlet :groupingTable
  outlet :groupLabelTable
    
  def awakeFromNib
    @notFoundFiles = Array.new
    @groupingTable.unbind("sortDescriptors")
    @groupLabelTable.unbind("sortDescriptors")
  end
    
  def prepareFileInfo(sender)
    
    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0 && @fileController.fileAryCtl.arrangedObjects.length == 0
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
    
    if Defaults['corpusMode'] == 1 && @appInfoObjCtl.content['fileInfoGroping'] == 2
      if (Defaults['mode'] == 0 && (@groupingAryCtl.arrangedObjects.map{|x| x['cdbname']} != @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|y| y['name']})) || (Defaults['mode'] == 1 && (@groupingAryCtl.arrangedObjects.map{|x| x['cdbname']} != @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.map{|y| y['name']}))
        alert = NSAlert.alertWithMessageText("Grouping is not specified.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"Please assign grouping to each corpus/database.")

        alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
        return
      end
    end
      
      
    @initTime = Time.now
    @fileInfoAryCtl.setSortDescriptors(nil)
    
    tableCols = @fileInfoTable.tableColumns[1...@fileInfoTable.tableColumns.length]
    tableCols.each{|x| @fileInfoTable.removeTableColumn(x)}
    
    if @appInfoObjCtl.content['fileInfoChoice'] != 0 && Defaults['lemmaCheck'] && NSApp.delegate.lemmas.nil?
      listItems = ListItemProcesses.new
      listItems.lemmaPrepare
    end
    
    
    @fileInfoAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@fileInfoAryCtl.arrangedObjects.length]))
    Dispatch::Queue.concurrent.async{
    
      case @appInfoObjCtl.content['fileInfoChoice']
      when 0
        self.fileInfoProcess(0)
        @currentFIType = 0
      when 1
        case @appInfoObjCtl.content['fileInfoListWordChoice']
        when 0
          if !Defaults['fileInfoTableColLimitCheck']
            alert = NSAlert.alertWithMessageText("Do you want to proceed?",
                                                defaultButton:"Proceed",
                                                alternateButton:"Cancel",
                                                otherButton:nil,
                                                informativeTextWithFormat:"If you display all the words on the table, the response will be extremely slow.")

            alert.buttons[1].setKeyEquivalent("\e")
            userChoice = alert.runModal
            return if userChoice == 0
          end
          self.fileInfoProcess(2)
          @currentFIType = 1
        when 1
          self.selectWordList(0)
          @currentFIType = 1
        when 2
          if !@appInfoObjCtl.content['fileInfoWordsText'].nil?
            self.fileInfoProcess(1)
            @currentFIType = 1
          else
            alert = NSAlert.alertWithMessageText("No word to count is entered.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"Please enter at least one word to count.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
            return
          end
        end
      when 2
        case @appInfoObjCtl.content['fileInfoListWordChoice']
        when 0
          self.fileInfoProcess(4)
          @currentFIType = 2
        when 1
          self.selectWordList(1)        
          @currentFIType = 2
        when 2
          self.fileInfoProcess(4)
          @appInfoObjCtl.content['fileInfoListWordChoice'] = 0
          @currentFIType = 2
        end
      when 3
        return if @importKGAryCtl.arrangedObjects.length == 0
        self.fileInfoProcess(6)
        @currentFIType = 3
      end
    
      Dispatch::Queue.main.async{
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
        @fileInfoTable.undoManager.removeAllActions
      }
    }
    
    NSApp.delegate.currentFileInfoMode = [Defaults['mode'],Defaults['corpusMode']]
  end
  
  
  def selectWordList(type)
    @startProcessBtn.setTag(type)
    @appInfoObjCtl.content['fileInfoImportInitNum'] = 1
    @appInfoObjCtl.content['fileInfoImportLastNum'] = 1
    if @wcController.wcLeftAryCtl.arrangedObjects.length == 0
      @appInfoObjCtl.content['fileInfoImportChoice'] = 1
    else
      @appInfoObjCtl.content['fileInfoImportChoice'] = 0
    end
    @appInfoObjCtl.content['fileInfoWLTextImportAdd'] = false
    @mainWindow.beginSheet(@importWLPanel,completionHandler:Proc.new { |returnCode| })    
  end

  def importWordList(sender)

    case @appInfoObjCtl.content['fileInfoImportChoice']
    when 0
      @importWLAryCtl.setSortDescriptors(nil)
      @importWLAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importWLAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
      @importWLAryCtl.addObjects(@wcController.wcLeftAryCtl.arrangedObjects.map{|x| {'word' => x['word']}})
    when 1
      @appInfoObjCtl.content['wcImportType'] = 0
      @appInfoObjCtl.content['wcImportIgnoreRows'] = 0
      @appInfoObjCtl.content['wcImportWordCol'] = 0
      
      panel = NSOpenPanel.openPanel
    	panel.setTitle("Select a word list file to import.")
    	panel.setCanChooseFiles(true)
    	panel.setAllowsMultipleSelection(false)
    	panel.setAccessoryView(@fiWLImportChoiceView)
      panel.setAllowedFileTypes([:txt])
      panel.beginSheetModalForWindow(@importWLPanel,completionHandler:Proc.new { |returnCode| 
        panel.close
        if returnCode == 1
          @importWLAryCtl.setSortDescriptors(nil)
      
          wlText = NSMutableString.alloc.initWithContentsOfFile(panel.filename,encoding:FileEncoding[@appInfoObjCtl.content['encoding']],error:nil)
          wordAry = Array.new
          separator = @appInfoObjCtl.content['wcImportType'] == 0 ? "\t" : ","
          wlText.lines.each_with_index do |line|
            items = line.strip.split(separator)
            next if items[@appInfoObjCtl.content['wcImportWordCol']].to_s == ""
            wordAry << {'word' => items[@appInfoObjCtl.content['wcImportWordCol']]}
          end
          @importWLAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importWLAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
          @importWLAryCtl.addObjects(wordAry)
        end

      })
    when 2
      @importWLPanel.beginSheet(@importWLTextPanel,completionHandler:Proc.new { |returnCode| })    
    end
    
  end
  
  
  
  
  def importWLText(sender)
    @importWLPanel.endSheet(@importWLTextPanel)
    case sender.tag
    when 0
      @importWLAryCtl.setSortDescriptors(nil)
      @importWLAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importWLAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
      wordAry = @importWLText.string.split(/\r|\r?\n/).delete_if{|x| x.strip == ""}.map{|x| {'word' => x.strip}}
      @importWLAryCtl.addObjects(wordAry)
      @appInfoObjCtl.content['fileInfoImportInitNum'] = 1
      @appInfoObjCtl.content['fileInfoImportLastNum'] = @importWLAryCtl.arrangedObjects.length
      return
    when 1
      return
    end
  end


  def selectKeyGroupList(sender)
    @appInfoObjCtl.content['fileInfoImportKGChoice'] = 0
    @appInfoObjCtl.content['fileInfoWLTextImportAdd'] = false
    @mainWindow.beginSheet(@importKGPanel,completionHandler:Proc.new { |returnCode| })    
  end


  def importKGList(sender)
    case @appInfoObjCtl.content['fileInfoImportKGChoice']
    when 0
      @importKGPanel.beginSheet(@importKGTextPanel,completionHandler:Proc.new { |returnCode| })    
    when 1
      @appInfoObjCtl.content['encoding'] = 0
      panel = NSOpenPanel.openPanel
    	panel.setTitle("Select a word list file to import.")
    	panel.setCanChooseFiles(true)
    	panel.setAllowsMultipleSelection(false)
    	panel.setAccessoryView(@encodingView)
      panel.setAllowedFileTypes([:txt])
      panel.beginSheetModalForWindow(@importKGPanel,completionHandler:Proc.new { |returnCode| 
        panel.close
        if returnCode == 1
          @importKGAryCtl.setSortDescriptors(nil)
      
          kgText = NSMutableString.alloc.initWithContentsOfFile(panel.filename,encoding:FileEncoding[@appInfoObjCtl.content['encoding']],error:nil)
          wordAry = Array.new
          kgText.lines.each_with_index do |line|
            next if line.strip == ""
            kg = line.strip.split("->")
            wordAry << {'keyword' => kg[0], 'words' => kg[1].to_s}
          end
          @importKGAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importKGAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
          @importKGAryCtl.addObjects(wordAry)
        end
      })
    end
    
  end
  
  def closeKGListPanel(sender)
    @mainWindow.endSheet(@importKGPanel)
  end
    
  
  def importKGText(sender)
    @importKGPanel.endSheet(@importKGTextPanel)
    case sender.tag
    when 0
      @importKGAryCtl.setSortDescriptors(nil)
      @importKGAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importWLAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
      wordAry = @importKGText.string.split(/\r|\r?\n/).delete_if{|x| x.strip == ""}.map{|x| x.split("->")}.map{|x,y| {'keyword' => x.strip,'words' => y.to_s.strip}}
      @importKGAryCtl.addObjects(wordAry)
      return
    when 1
      return
    end
  end

  
  def pasteKGText(sender)
    pasteBoard = NSPasteboard.generalPasteboard
    data = pasteBoard.stringForType(NSPasteboardTypeString)
    @importKGAryCtl.setSortDescriptors(nil)
    @importKGAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@importWLAryCtl.arrangedObjects.length])) if !@appInfoObjCtl.content['fileInfoWLTextImportAdd']
    if @appInfoObjCtl.content['fileinfoKWGroupAutoIDCheck']
      wordAry = data.split(/\r|\r?\n/).delete_if{|x| x.strip == ""}.map{|x| x.split(/\->|\t/)}.map.with_index{|x,i| {'keyword' => (i + 1),'words' => x[0].to_s.strip}}
    else
      wordAry = data.split(/\r|\r?\n/).delete_if{|x| x.strip == ""}.map{|x| x.split(/\->|\t/)}.map{|x,y| {'keyword' => x.strip,'words' => y.to_s.strip}}
    end
    @importKGAryCtl.addObjects(wordAry)
    
  end


  def processLemmatize(sender)
    if NSApp.delegate.lemmas.nil?
      listItems = ListItemProcesses.new
      listItems.lemmaPrepare
    end
    @importKGAryCtl.arrangedObjects.each do |item|
      if item['words'].to_s == ""
        item['words'] = NSApp.delegate.lemmas[item['keyword']].split('|').sort_by{|x| x.length}.join(",")
      end
    end
    @importKGTable.reloadData
  end


  def startFileInfoProcess(sender)
    @mainWindow.endSheet(@importWLPanel)
    @fileInfoAryCtl.setSortDescriptors(nil)
    
    case sender.tag
    when 2
      return
    when 0
      self.fileInfoProcess(3)
    when 1
      self.fileInfoProcess(5)
    end
  end



  def fileInfoProcess(fiMode)
    @fileInfoHash = Hash.new{|hash,key| hash[key] = Hash.new(0)}
    @foundFileHash = Hash.new{|hash,key| hash[key] = Hash.new(0)}
    
    @pathHash = Hash.new
    @pathCount = Hash.new(0)
    @maxlgth = 0
    @totalWLength = 0
    @notFoundFiles = Array.new
    if !Defaults['fileInfoCaseSensitivity']
      caseSensitivity = Regexp::IGNORECASE
	  else
	    caseSensitivity = 0
    end
		
    if fiMode == 1
      wordReg = Regexp.new(@appInfoObjCtl.content['fileInfoWordsText'].split(",").map{|x| "\\b(#{x.strip.gsub(/\//,"|")})\\b"}.join("|"),caseSensitivity)
    else
      wordReg = Regexp.new(WildWordProcess.new("word").wildWord,caseSensitivity)
    end
    
    wordListHash = Hash.new("")
    if fiMode == 3 || fiMode == 5
      @importWLAryCtl.arrangedObjects.each do |item|
        wordListHash[item['word']] = item['word']
      end
    elsif fiMode == 6
      @importKGAryCtl.arrangedObjects.each do |item|
        case Defaults['fileInfoKKeyGroupEntryDivider']
        when 0
          divider = /[\/,]/
        when 1
          divider = /,/
        when 2
          divider = /\//
        end
        case Defaults['fileInfoKeyGroupCapital']
        when
          regCase = Regexp::IGNORECASE
        when
          regCase = 0
        end
        if item['words'].to_s != ""
          wordListHash[item['keyword']] = Array.new
          item['words'].split(/\ *\#\#EXCEPT\#\#\ */).each_with_index do |subEnt,subEntIdx|
             wordListHash[item['keyword']] << Regexp.new('\b(?:'+subEnt.split(divider).uniq.sort_by{|x| -x.length}.join('|')+')\b',regCase)
          end
        else
          wordListHash[item['keyword']] = Array.new
          wordListHash[item['keyword']] << Regexp.new('\b(?:'+item['keyword']+')\b',regCase)
        end
      end
    end

    tagProcessItems = @fileController.tagPreparation if Defaults['tagModeEnabled']

    if Defaults['mode'] == 0 && Defaults['corpusMode'] == 0
      filesToProcess = @fileController.fileAryCtl.arrangedObjects.length
      if filesToProcess > 1
        NSApp.delegate.progressBar.stopAnimation(nil)
        NSApp.delegate.progressBar.setIndeterminate(false)
        NSApp.delegate.progressBar.setMinValue(0.0)  
        NSApp.delegate.progressBar.setMaxValue(filesToProcess)
        NSApp.delegate.progressBar.setDoubleValue(0.0)
        NSApp.delegate.progressBar.displayIfNeeded
      end

      @fileController.fileAryCtl.arrangedObjects.each_with_index do |item,idx|
        if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
          @notFoundFiles << item['path']
          next
        end
        inText = @fileController.readFileContents(item['path'],item['encoding'],"fileInfo",tagProcessItems,nil)
        inText.downcase! if !Defaults['fileInfoCaseSensitivity']
        @pathHash[idx] = item['path']
        self.selectFileInfoProcess(fiMode,inText,wordReg,idx,wordListHash)
        NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess > 0
      end

      if filesToProcess > 0
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
    elsif Defaults['mode'] == 0 && Defaults['corpusMode'] == 1
      filesToProcess = Array.new
      currentCDs = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(",")
      NSApp.delegate.currentFileInfoCDs = currentCDs#.join(", ")
      @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
        filesToProcess << [NSMutableArray.arrayWithContentsOfFile(corpusItem['path']),corpusItem['name']]
      end
      
      if @appInfoObjCtl.content['fileInfoGroping'] == 2
        gpHash = Hash.new
        @groupingAryCtl.arrangedObjects.each do |item|
          if item['gpSelection'] == 1
            gpHash[item['cdbname']] = item['labels'] == "" ? item['cdbname'] : item['labels']
          else
            fnAry = NSArray.arrayWithContentsOfFile(item['path']).map{|x| x['filename']}
            gpHash[item['cdbname']] = Hash.new
            if item['labelAry'].length > 0
              item['labelAry'].each_with_index do |var,idx|
                if var != ""
                  gpHash[item['cdbname']][fnAry[idx]] = var
                else
                  gpHash[item['cdbname']][fnAry[idx]] = File.basename(fnAry[idx],".*")
                end
              end
            else
              fnAry.each do |var|
                gpHash[item['cdbname']][var] = File.basename(var,".*")
              end
            end
          end
        end
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
      fidx = 0
      gpidx = -1
      prevGroup = ""
      filesToProcess.each_with_index do |corpusItem,cidx|
        corpusItem[0].each do |item|
          if !NSFileManager.defaultManager.fileExistsAtPath(item['path'])
            @notFoundFiles << item['path']
            next
          end
          inText = @fileController.readFileContents(item['path'],item['encoding'],"fileInfo",tagProcessItems,nil)
          inText.downcase! if !Defaults['fileInfoCaseSensitivity']
          case @appInfoObjCtl.content['fileInfoGroping']
          when 0
            gidx = fidx
            @pathHash[fidx] = item['path']
          when 1
            gidx = cidx
            @pathHash[cidx] = corpusItem[1]
          when 2
            if gpHash[corpusItem[1]].is_a?(String)
              gpidx += 1 if prevGroup != gpHash[corpusItem[1]]
              gidx = gpidx
              @pathHash[gidx] = gpHash[corpusItem[1]]
              prevGroup = gpHash[corpusItem[1]]
            else
              gpidx += 1
              gidx = gpidx
              @pathHash[gidx] = gpHash[corpusItem[1]][File.basename(item['path'])]
            end
          end
          self.selectFileInfoProcess(fiMode,inText,wordReg,gidx,wordListHash)
          NSApp.delegate.progressBar.incrementBy(1.0) if totalFilesToProcess > 1
          fidx += 1
        end
      end

      if totalFilesToProcess > 1
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.startAnimation(nil)
      end
    elsif Defaults['mode'] == 1 && Defaults['corpusMode'] == 0
      NSApp.delegate.currentFileInfoCDs = "text"
      inText = NSApp.delegate.inputText.string.dup
      inText.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
      inText = @fileController.tagApplication(inText,tagProcessItems,"fileInfo","current") if Defaults['tagModeEnabled']
      inText.downcase! if !Defaults['fileInfoCaseSensitivity']
      
      return [] if inText.length == 0
      self.selectFileInfoProcess(fiMode,inText,wordReg,nil,wordListHash)
    else
      filesToProcess = Array.new
      totalFilesToProcess = 0
      @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.each do |corpusItem|
        fileIDs = Array.new
        autorelease_pool {        
          db = FMDatabase.databaseWithPath(corpusItem['path'])
          db.open
            results = db.executeQuery("SELECT DISTINCT file_id,path FROM conc_data")
            while results.next
              items = results.resultDictionary
              fileIDs << [items['file_id'],items['path']]
            end
            totalFilesToProcess += fileIDs.length
            filesToProcess << [corpusItem['path'],fileIDs]
            results.close            
          db.close
        }
      end

      currentCDs = filesToProcess.map{|x| File.basename(x[0],".*")}
      NSApp.delegate.currentFileInfoCDs = currentCDs.join(",")
      
      
      if @appInfoObjCtl.content['fileInfoGroping'] == 2     
        gpHash = Hash.new
        @groupingAryCtl.arrangedObjects.each do |item|
          if item['gpSelection'] == 1
            gpHash[item['cdbname']] = item['labels'] == "" ? item['cdbname'] : item['labels']
          else
            fnAry = Array.new
            
            autorelease_pool {        
              db = FMDatabase.databaseWithPath(corpusItem['path'])
              db.open
                results = db.executeQuery("SELECT DISTINCT path FROM conc_data")
                while results.next
                  fnAry << results.resultDictionary['path']
                end
                gpHash[item['cdbname']] = Hash.new
                if item['labelAry'].length > 0
                  item['labelAry'].each_with_index do |var,idx|
                    if var != ""
                      gpHash[item['cdbname']][fnAry[idx]] = var
                    else
                      gpHash[item['cdbname']][fnAry[idx]] = File.basename(fnAry[idx],".*")
                    end
                  end
                else
                  fnAry.each do |var|
                    gpHash[item['cdbname']][var] = File.basename(var,".*")
                  end
                end
                results.close            
              db.close
            }              
          end
        end
      end

      case fiMode
      when 1
        fname = ""
        idx = -1
        sqlSearchWords = @appInfoObjCtl.content['fileInfoWordsText'].split(/[,\/]/).map{|x| "text LIKE '%#{x.strip}%'"}.join(" OR ")
        filesToProcess.each_with_index do |ccdb,cidx|
          autorelease_pool {
            db = FMDatabase.databaseWithPath(ccdb[0])
            db.open
              textAry = Array.new
              results = db.executeQuery("SELECT text,path FROM conc_data WHERE #{sqlSearchWords}")
              while results.next
                path = results.resultDictionary['path'].mutableCopy
                inText = results.resultDictionary['text'].mutableCopy
                inText.downcase! if !Defaults['fileInfoCaseSensitivity']
                case @appInfoObjCtl.content['fileInfoGroping']
                when 0
                  if fname != path
                    fname = path
                    idx += 1
                  end
                  @pathHash[idx] = path
                when 1
                  if fname != File.basename(ccdb[0],".*")
                    fname = File.basename(ccdb[0],".*")
                    idx += 1
                  end
                  @pathHash[idx] = path                
                when 2
                  if gpHash[File.basename(ccdb[0],".*")].is_a?(String)
                    gpidx += 1 if prevGroup != gpHash[File.basename(ccdb[0],".*")]
                    gidx = gpidx
                    @pathHash[gidx] = gpHash[File.basename(ccdb[0],".*")]
                    prevGroup = gpHash[File.basename(ccdb[0],".*")]
                  else
                    gpidx += 1
                    gidx = gpidx
                    @pathHash[gidx] = gpHash[File.basename(ccdb[0],".*")][File.basename(item[1])]
                  end                   
                end
                self.selectFileInfoProcess(fiMode,inText,wordReg,idx,wordListHash)
              end
              results.close
            db.close
          }          
        end
      else

        
        
        if filesToProcess.length > 1
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(totalFilesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
        end
        fidx = 0
        gpidx = -1
        prevGroup = ""
        filesToProcess.each_with_index do |ccdb,cidx|

          autorelease_pool {        
            db = FMDatabase.databaseWithPath(ccdb[0])
            db.open            
              ccdb[1].each do |item|
                textAry = Array.new
                results = db.executeQuery("select text from conc_data where file_id == ? order by id",item[0])
                while results.next
                  textAry << results.resultDictionary['text'].mutableCopy
                end
                inText = textAry.join("\n\n")
                inText.downcase! if !Defaults['fileInfoCaseSensitivity']
                case @appInfoObjCtl.content['fileInfoGroping']
                when 0
                  gidx = fidx
                  @pathHash[fidx] = item[1]
                when 1
                  gidx = cidx
                  @pathHash[cidx] = File.basename(ccdb[0],".*")
                when 2
                  if gpHash[File.basename(ccdb[0],".*")].is_a?(String)
                    gpidx += 1 if prevGroup != gpHash[File.basename(ccdb[0],".*")]
                    gidx = gpidx
                    @pathHash[gidx] = gpHash[File.basename(ccdb[0],".*")]
                    prevGroup = gpHash[File.basename(ccdb[0],".*")]
                  else
                    gpidx += 1
                    gidx = gpidx
                    @pathHash[gidx] = gpHash[File.basename(ccdb[0],".*")][File.basename(item[1])]
                  end                
                end
                self.selectFileInfoProcess(fiMode,inText,wordReg,gidx,wordListHash)
                NSApp.delegate.progressBar.incrementBy(1.0) if filesToProcess.length > 1
                fidx += 1
                results.close
              end
            db.close
          }
        end
        if filesToProcess.length > 1
          NSApp.delegate.progressBar.setIndeterminate(true)
          NSApp.delegate.progressBar.startAnimation(nil)
        end
        
      end
    end
    self.tableProcess(fiMode)
  end


  def tableProcess(fiMode)
    case fiMode
    when 0
      self.fileInfoTableProcess
    when 1
      self.wordListTableProcess(0)
    when 2,3
      self.wordListTableProcess(1)
    when 4,5
      self.tfidfTableProcess
    when 6
      self.wordListTableProcess(1)
    end
  end
  
  
  def fileInfoTableProcess
    dataAry = Array.new
    if Defaults['fileInfoTTRStd']
      titles = [['Types','types',"#,##0"],['Tokens','tokens',"#,##0"],['TTR','ttr',"#,##0.00"],['STDTTR','stdttr',"#,##0.00"],['Ave W Lgth','aveLgth',"#,##0.00"]]
    else
      titles = [['Types','types',"#,##0"],['Tokens','tokens',"#,##0"],['TTR','ttr',"#,##0.00"],['Ave W Lgth','aveLgth',"#,##0.00"]]
    end

    fileHash = Hash.new
    fileHash['ccFIGroup'] = " TOTAL"
    fileHash['tokens'] = @fileInfoHash['ccFileInfoTotal']['tokens']
    fileHash['types'] = @fileInfoHash['ccFileInfoTotal']['types']
    fileHash['ttr'] = @fileInfoHash['ccFileInfoTotal']['types']/@fileInfoHash['ccFileInfoTotal']['tokens'].to_f * 100
    if Defaults['fileInfoTTRStd']
      fileHash['stdttr'] = @fileInfoHash['ccFileInfoTotal']['stdttr']/@pathCount.length#.inject(0){|num,freq| num + freq[1]}
    end
    if @maxlgth > 15 && !Defaults['fileInfoWordLgthDetail']
      (1..16).each do |i|
        fileHash["l#{i}"] = @fileInfoHash['ccFileInfoTotal']["l#{i}"]
      end
    else
      (1..@maxlgth).each do |i|
        fileHash["l#{i}"] = @fileInfoHash['ccFileInfoTotal']["l#{i}"]
      end
    end
    fileHash['aveLgth'] = @totalWLength/@fileInfoHash['ccFileInfoTotal']['tokens'].to_f
    
    dataAry << fileHash

    @fileInfoHash.each do |file,item|
      next if file == 'ccFileInfoTotal'
      fileHash = Hash.new
      fileHash['ccFIGroup'] = File.basename(@pathHash[file])
      fileHash['tokens'] = item['tokens']
      fileHash['types'] = item['types']
      fileHash['aveLgth'] = item['aveLgth']
      case @appInfoObjCtl.content['fileInfoGroping']
      when 0
        #fileHash['ttr'] = item['ttr']      
        fileHash['ttr'] = item['types']/item['tokens'].to_f * 100
        if Defaults['fileInfoTTRStd']
          fileHash['stdttr'] = item['stdttr']
        end
      when 1
        fileHash['ttr'] = item['types']/item['tokens'].to_f * 100
        if Defaults['fileInfoTTRStd']
          fileHash['stdttr'] = item['stdttr']/@pathCount[file]
        end
      when 2
        fileHash['ttr'] = item['types']/item['tokens'].to_f * 100
        if Defaults['fileInfoTTRStd']
          fileHash['stdttr'] = item['stdttr']/@pathCount[file]
        end
      end
      if @maxlgth > 15 && !Defaults['fileInfoWordLgthDetail']
        (1..16).each do |i|
          fileHash["l#{i}"] = item["l#{i}"]
        end
      else
        (1..@maxlgth).each do |i|
          fileHash["l#{i}"] = item["l#{i}"]
        end
      end
      dataAry << fileHash
    end

    Dispatch::Queue.main.async{

      titles.each do |title,id,format|
        @fileInfoTable.addTableColumn(self.createTableCol(title,id,format,NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
      end
      if @maxlgth > 15 && !Defaults['fileInfoWordLgthDetail']
        (1..16).each do |i|
          if i == 1
            @fileInfoTable.addTableColumn(self.createTableCol("1 letter","l#{i}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
          elsif i == 16
            @fileInfoTable.addTableColumn(self.createTableCol("16+ letters","l#{i}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
          else
            @fileInfoTable.addTableColumn(self.createTableCol("#{i} letters","l#{i}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
          end          
        end
      else
        (1..@maxlgth).each do |i|
          if i == 1
            @fileInfoTable.addTableColumn(self.createTableCol("1 letter","l#{i}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
          else
            @fileInfoTable.addTableColumn(self.createTableCol("#{i} letters","l#{i}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
          end
        end
      end
    
      @fileInfoAryCtl.addObjects(dataAry)
      NSApp.delegate.progressBar.stopAnimation(nil)
    
      @appInfoObjCtl.content['timer'] = Time.now - @initTime
    }
  end
  
  
  
  def wordListTableProcess(type)
    dataAry = Array.new
    case type
    when 0
      labels = @appInfoObjCtl.content['fileInfoWordsText'].split(",")
      @fileInfoHash.each do |file,item|
        fileHash = Hash.new(0)
        next if file == 'ccFileInfoTotal'
        fileHash['ccFIGroup'] = File.basename(@pathHash[file])
        totalNum = item.inject(0){|num,wd| num + wd[1]}
        fileHash['ccFITotalFreq'] = totalNum
        labels.length.times do |i|
          fileHash["ccFIItem#{i}"] = item[i]
        end
        dataAry << fileHash
      end
      Dispatch::Queue.main.async{
        @fileInfoAryCtl.addObjects(dataAry.sort_by{|x| x['ccFIGroup']})
      }
      fileHash = Hash.new(0)
      fileHash['ccFIGroup'] = " TOTAL"
      totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,wd| num + wd[1]}
      fileHash['ccFITotalFreq'] = totalNum
      labels.length.times do |i|
        fileHash["ccFIItem#{i}"] = @fileInfoHash['ccFileInfoTotal'][i]
      end
      #fileHash.delete("")
      Dispatch::Queue.main.async{
        @fileInfoAryCtl.addObject(fileHash)
        labels.each_with_index do |title,idx|
          @fileInfoTable.addTableColumn(self.createTableCol(title,"ccFIItem#{idx}","#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
        end
        @fileInfoTable.addTableColumn(self.createTableCol("Total",'ccFITotalFreq',"#,##0",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
      }
    when 1
      if !Defaults['fileInfoWFOrderByCheck']
        if @appInfoObjCtl.content['fileInfoChoice'] == 1 && @appInfoObjCtl.content['fileInfoListWordChoice'] == 0 
          colWidth = 65 + @appInfoObjCtl.content['fileInfoWLChoice'] * 25
        else
          colWidth = 65
        end
        if Defaults['fileInfoWFStdCheck']
          fileHash = Hash.new(0)
          fileHash['ccFIGroup'] = " TOTAL"
          totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,item| num + item[1]}
          fileHash['ccFITotalFreq'] = totalNum
          @fileInfoHash.delete("")
          wordHash = Hash.new
          @itemOrder = Array.new
          case Defaults['fileInfoWFStdChoice']
          when 0
            @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              @itemOrder << item[0]
              fileHash["ccFIItem#{idx+1}"] = item[1]/totalNum.to_f
              wordHash[item[0]] = "ccFIItem#{idx+1}"
            end
          when 1
            @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              @itemOrder << item[0]
              fileHash["ccFIItem#{idx+1}"] = item[1]/totalNum.to_f * Defaults['fileInfoWFStdPerWds']
              wordHash[item[0]] = "ccFIItem#{idx+1}"
            end
          end
          Dispatch::Queue.main.async{
            @fileInfoAryCtl.addObject(fileHash)
          }
          dataAry = Array.new
          @fileInfoHash.delete('ccFileInfoTotal')
          @fileInfoHash.each do |file,item|
            fileHash = Hash.new(0)
            fileHash['ccFIGroup'] = File.basename(@pathHash[file])
            totalNum = item.inject(0){|num,wd| num + wd[1]}
            fileHash['ccFITotalFreq'] = totalNum
            item.delete("")
            case Defaults['fileInfoWFStdChoice']
            when 0
              item.each do |word,freq|
                fileHash[wordHash[word]] = freq/totalNum.to_f
              end
            when 1
              item.each do |word,freq|
                fileHash[wordHash[word]] = freq/totalNum.to_f * Defaults['fileInfoWFStdPerWds']
              end
            end
            Dispatch::Queue.main.async{
              @fileInfoAryCtl.addObject(fileHash)
            }
          end
          Dispatch::Queue.main.async{
            @fileInfoTable.addTableColumn(self.createTableCol("Total",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))
            case Defaults['fileInfoWFStdChoice']
            when 0
              @itemOrder.each_with_index do |title,idx|
                if Defaults['fileInfoTableColLimitCheck']
                  break if Defaults['fileInfoTableColLimitNum'] == idx
                end
                @fileInfoTable.addTableColumn(self.createTableCol(title,"ccFIItem#{idx+1}","#,##0.00%",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))
              end
            when 1
              @itemOrder.each_with_index do |title,idx|
                if Defaults['fileInfoTableColLimitCheck']
                  break if Defaults['fileInfoTableColLimitNum'] == idx
                end
                @fileInfoTable.addTableColumn(self.createTableCol(title,"ccFIItem#{idx+1}","#,##0.00",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
              end
            end
          }
        else
          fileHash = Hash.new(0)
          fileHash['ccFIGroup'] = " TOTAL"
          wordHash = Hash.new
          @itemOrder = Array.new
          totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,item| num + item[1]}
          fileHash['ccFITotalFreq'] = totalNum
          @fileInfoHash.delete("")
          @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
            @itemOrder << item[0]
            fileHash["ccFIItem#{idx+1}"] = item[1]
            wordHash[item[0]] = "ccFIItem#{idx+1}"
          end
          Dispatch::Queue.main.async{
            @fileInfoAryCtl.addObject(fileHash)
          }
          @fileInfoHash.delete('ccFileInfoTotal')
          @fileInfoHash.each do |file,item|
            fileHash = Hash.new(0)
            fileHash['ccFIGroup'] = File.basename(@pathHash[file])
            totalNum = item.inject(0){|num,wd| num + wd[1]}
            fileHash['ccFITotalFreq'] = totalNum
            item.delete("")
            item.each do |word,freq|
              fileHash[wordHash[word]] = freq
            end
            Dispatch::Queue.main.async{
              @fileInfoAryCtl.addObject(fileHash)
            }
          end
          Dispatch::Queue.main.async{
            @fileInfoTable.addTableColumn(self.createTableCol("Total",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))
            @itemOrder.each_with_index do |title,idx|
              if Defaults['fileInfoTableColLimitCheck']
                break if Defaults['fileInfoTableColLimitNum'] == idx
              end
              @fileInfoTable.addTableColumn(self.createTableCol(title,"ccFIItem#{idx+1}","#,##0",NSNumberFormatterDecimalStyle,colWidth,NSRightTextAlignment))
            end
          }
        end
      else
        if @appInfoObjCtl.content['fileInfoChoice'] == 1 && @appInfoObjCtl.content['fileInfoListWordChoice'] == 0 
          colWidth = 120 + @appInfoObjCtl.content['fileInfoWLChoice'] * 25
        else
          colWidth = 120
        end
        if Defaults['fileInfoWFStdCheck']
          fileHash = Hash.new(0)
          fileHash['ccFIGroup'] = " TOTAL"
          totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,item| num + item[1]}
          fileHash['ccFITotalFreq'] = totalNum
          @fileInfoHash.delete("")
          wordNum = @fileInfoHash['ccFileInfoTotal'].length
          case Defaults['fileInfoWFStdChoice']
          when 0
            @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{sprintf("%.2f%",item[1]/totalNum.to_f * 100)})"
            end
          when 1
            @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{sprintf("%.2f",item[1]/totalNum.to_f * Defaults['fileInfoWFStdPerWds'])})"
            end
          end
          Dispatch::Queue.main.async{
            @fileInfoAryCtl.addObject(fileHash)
          }
          dataAry = Array.new
          @fileInfoHash.delete('ccFileInfoTotal')
          @fileInfoHash.each do |file,item|
            fileHash = Hash.new(0)
            fileHash['ccFIGroup'] = File.basename(@pathHash[file])
            totalNum = item.inject(0){|num,wd| num + wd[1]}
            fileHash['ccFITotalFreq'] = totalNum
            item.delete("")
            case Defaults['fileInfoWFStdChoice']
            when 0
              item.sort_by{|x,y| [-y,x]}.each_with_index do |itm,idx|
                fileHash["ccFIItem#{idx+1}"] = "#{itm[0]} (#{sprintf("%.2f%",itm[1]/totalNum.to_f * 100)})"
              end
            when 1
              item.sort_by{|x,y| [-y,x]}.each_with_index do |itm,idx|
                fileHash["ccFIItem#{idx+1}"] = "#{itm[0]} (#{sprintf("%.2f",itm[1]/totalNum.to_f * Defaults['fileInfoWFStdPerWds'])})"
              end
            end
            Dispatch::Queue.main.async{
              @fileInfoAryCtl.addObject(fileHash)
            }
          end
          Dispatch::Queue.main.async{
            @fileInfoTable.addTableColumn(self.createTableCol("Total",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))
            case Defaults['fileInfoWFStdChoice']
            when 0
              wordNum.times do |idx|
                if Defaults['fileInfoTableColLimitCheck']
                  break if Defaults['fileInfoTableColLimitNum'] == idx
                end
                @fileInfoTable.addTableColumn(self.createTableCol("ccFIItem#{idx+1}","ccFIItem#{idx+1}",nil,nil,colWidth,NSLeftTextAlignment))
              end
            when 1
              wordNum.times do |idx|
                if Defaults['fileInfoTableColLimitCheck']
                  break if Defaults['fileInfoTableColLimitNum'] == idx
                end
                @fileInfoTable.addTableColumn(self.createTableCol("ccFIItem#{idx+1}","ccFIItem#{idx+1}",nil,nil,colWidth,NSLeftTextAlignment))
              end
            end
          }
        else
          fileHash = Hash.new(0)
          fileHash['ccFIGroup'] = " TOTAL"
          #wordHash = Hash.new
          wordNum = @fileInfoHash['ccFileInfoTotal'].length
          totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,item| num + item[1]}
          fileHash['ccFITotalFreq'] = totalNum
          @fileInfoHash.delete("")
          @fileInfoHash['ccFileInfoTotal'].sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
            fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{item[1]})"
            #wordHash[item[0]] = "ccFIItem#{idx+1}"
          end
          Dispatch::Queue.main.async{
            @fileInfoAryCtl.addObject(fileHash)
          }
          @fileInfoHash.delete('ccFileInfoTotal')
          @fileInfoHash.each do |file,item|
            fileHash = Hash.new(0)
            fileHash['ccFIGroup'] = File.basename(@pathHash[file])
            totalNum = item.inject(0){|num,wd| num + wd[1]}
            fileHash['ccFITotalFreq'] = totalNum
            item.delete("")
            item.sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
              fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{item[1]})"
            end
            Dispatch::Queue.main.async{
              @fileInfoAryCtl.addObject(fileHash)
            }
          end
          Dispatch::Queue.main.async{
            @fileInfoTable.addTableColumn(self.createTableCol("Total",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))
            wordNum.times do |idx|
              if Defaults['fileInfoTableColLimitCheck']
                break if Defaults['fileInfoTableColLimitNum'] == idx
              end
              @fileInfoTable.addTableColumn(self.createTableCol("ccFIItem#{idx+1}","ccFIItem#{idx+1}",nil,nil,colWidth,NSLeftTextAlignment))
            end
          }
        end
      end
    when 2
      
    end
    
    NSApp.delegate.progressBar.stopAnimation(nil)
    
    @appInfoObjCtl.content['timer'] = Time.now - @initTime
    
  end


  def tfidfTableProcess
    dataAry = Array.new
    totalFiles = @fileInfoHash.length - 1
    totalNum = @fileInfoHash['ccFileInfoTotal'].inject(0){|num,item| num + item[1]}
    wordNum = @fileInfoHash['ccFileInfoTotal'].length
    totalHash = Hash.new(0)
    totalNumHash = Hash.new(0)
    fileAry = Array.new
    @fileInfoHash.delete('ccFileInfoTotal')
    @fileInfoHash.each do |file,item|
      totalNumHash[file] = item.inject(0){|num,wd| num + wd[1]}
      item.each do |word,freq|
        item[word] = freq * log(totalFiles/@foundFileHash[word].length.to_f)
        totalHash[word] += freq * log(totalFiles/@foundFileHash[word].length.to_f)
      end
    end
    @itemOrder = Array.new
    wordHash = Hash.new

    case Defaults['fileInfoTFIDFSortChoice']
    when 0
      fileHash = Hash.new
      fileHash['ccFIGroup'] = " TOTAL" 
      fileHash['ccFITotalFreq'] = totalNum

      totalHash.sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
        @itemOrder << item[0]
        fileHash["ccFIItem#{idx+1}"] = item[1]
        wordHash[item[0]] = "ccFIItem#{idx+1}"
      end

      Dispatch::Queue.main.async{
        @fileInfoAryCtl.addObject(fileHash)
      }
      
      @fileInfoHash.each do |file,item|
        fileHash = Hash.new
        fileHash['ccFIGroup'] = File.basename(@pathHash[file])
        fileHash['ccFITotalFreq'] = totalNumHash[file]
        item.each do |word,val|
          fileHash[wordHash[word]] = val
        end
        Dispatch::Queue.main.async{
          @fileInfoAryCtl.addObject(fileHash)
        }
      end
      
      Dispatch::Queue.main.async{
        @fileInfoTable.addTableColumn(self.createTableCol("Tokens",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))

        @itemOrder.each_with_index do |title,idx|
          if Defaults['fileInfoTableColLimitCheck']
            break if Defaults['fileInfoTableColLimitNum'] == idx
          end
          @fileInfoTable.addTableColumn(self.createTableCol(title,"ccFIItem#{idx+1}","#,###.00",NSNumberFormatterDecimalStyle,65,NSRightTextAlignment))
        end    
      }
    when 1
      fileHash = Hash.new
      fileHash['ccFIGroup'] = " TOTAL"
      fileHash['ccFITotalFreq'] = totalNum
      totalHash.sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
        @itemOrder << item[0]
        fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{sprintf("%.2f",item[1])})"
      end
      Dispatch::Queue.main.async{
        @fileInfoAryCtl.addObject(fileHash)
      }
      @fileInfoHash.each do |file,item|
        fileHash = Hash.new
        fileHash['ccFIGroup'] = File.basename(@pathHash[file])
        fileHash['ccFITotalFreq'] = totalNumHash[file]
        item.sort_by{|x,y| [-y,x]}.each_with_index do |item,idx|
          fileHash["ccFIItem#{idx+1}"] = "#{item[0]} (#{sprintf("%.2f",item[1])})"
        end
        Dispatch::Queue.main.async{
          fileInfoAryCtl.addObject(fileHash)
        }
      end
      Dispatch::Queue.main.async{
        @fileInfoTable.addTableColumn(self.createTableCol("Tokens",'ccFITotalFreq',"#,##0",NSNumberFormatterPercentStyle,65,NSRightTextAlignment))

        wordNum.times do |idx|
          if Defaults['fileInfoTableColLimitCheck']
            break if Defaults['fileInfoTableColLimitNum'] == idx
          end
          @fileInfoTable.addTableColumn(self.createTableCol("Rank #{idx+1}","ccFIItem#{idx+1}",nil,nil,120,NSLeftTextAlignment))
        end
      }
    end


    NSApp.delegate.progressBar.stopAnimation(nil)
    
    @appInfoObjCtl.content['timer'] = Time.now - @initTime
    
  end



  def createTableCol(title,id,format,style,width,alignment)
    column = NSTableColumn.alloc.initWithIdentifier(id)
    column.setWidth(width)
    column.setMinWidth(width)
    headerCell = NSTableHeaderCell.alloc.initTextCell(title)
    column.setHeaderCell(headerCell)
    column.setEditable(false)
    textCell = NSTextFieldCell.alloc.init
    textCell.setAlignment(alignment)
    if !format.nil?
      formatter = NSNumberFormatter.alloc.init
      formatter.setFormatterBehavior(NSNumberFormatterBehavior10_4)
      formatter.setNumberStyle(style)
      formatter.setFormat(format)
      textCell.setFormatter(formatter)
    end
    column.setDataCell(textCell)
    column.setSortDescriptorPrototype(NSSortDescriptor.sortDescriptorWithKey(id,ascending:true,selector:"compare:"))
    column.bind("value",toObject:@fileInfoAryCtl,withKeyPath:"arrangedObjects.#{id}",options:nil)
    return column
  end
  
  

  def selectFileInfoProcess(fiMode,inText,wordReg,idx,wordListHash)
    case fiMode
    when 0
      self.createFileInfo(inText,wordReg,idx)
    when 1
      self.createWordCountTable(inText,wordReg,idx)
    when 2
      self.createEachWordList(inText,wordReg,idx)
    when 3
      self.createSelectedWordList(inText,wordReg,idx,wordListHash)
    when 4
      self.createTFIDF(inText,wordReg,idx)
    when 5
      self.createSelectedTFIDF(inText,wordReg,idx,wordListHash)
    when 6
      self.createKeyGroupList(inText,idx,wordListHash)
    end
  end
  
  
  def createFileInfo(inText,wordReg,idx)
    words = inText.scan(wordReg)
    tokens = words.length
    types = words.uniq.length
    #case @appInfoObjCtl.content['fileInfoGroping']
    #when 0
    #  @fileInfoHash[idx]['ttr'] += types/tokens.to_f * 100
    #end
    @pathCount[idx] += 1
    if Defaults['fileInfoTTRStd']
      tempTTR = 0
      i = 0
      #while !(stdText = words[i*Defaults['fileInfoSTTRNum'],Defaults['fileInfoSTTRNum']]).nil?
      while (stdText = words[i*Defaults['fileInfoSTTRNum'],Defaults['fileInfoSTTRNum']]).length == Defaults['fileInfoSTTRNum']
        tempTTR += stdText.uniq.length/stdText.length.to_f * 100 #Defaults['fileInfoSTTRNum']
        i += 1
      end
      @fileInfoHash[idx]['stdttr'] = i == 0 ? types/tokens.to_f * 100 : tempTTR/i #tempTTR/i
      @fileInfoHash['ccFileInfoTotal']['stdttr'] += i == 0 ? types/tokens.to_f * 100 : tempTTR/i #tempTTR/i
    end
    @fileInfoHash[idx]['tokens'] += tokens
    @fileInfoHash[idx]['types'] += types
    @fileInfoHash['ccFileInfoTotal']['tokens'] += tokens
    @fileInfoHash['ccFileInfoTotal']['types'] += types
    totalWordLength = 0
    if !Defaults['fileInfoWordLgthDetail']
      words.each do |word|
        wlgth = word.strip.length
        totalWordLength += wlgth
        @totalWLength += wlgth
        @maxlgth = wlgth if @maxlgth < wlgth
        if wlgth < 16
          @fileInfoHash[idx]["l#{wlgth}"] += 1
          @fileInfoHash['ccFileInfoTotal']["l#{wlgth}"] += 1
        else
          @fileInfoHash[idx]["l16"] += 1
          @fileInfoHash['ccFileInfoTotal']["l16"] += 1
        end
      end
    else
      words.each do |word|
        wlgth = word.strip.length
        totalWordLength += wlgth
        @totalWLength += wlgth
        @maxlgth = wlgth if @maxlgth < wlgth
        @fileInfoHash[idx]["l#{wlgth}"] += 1
        @fileInfoHash['ccFileInfoTotal']["l#{wlgth}"] += 1
      end
    end
    @fileInfoHash[idx]['aveLgth'] = totalWordLength/tokens.to_f
  end
  
  
  def createWordCountTable(inText,wordReg,idx)
    words = inText.scan(wordReg)
    words.length.times do |i|
      @fileInfoHash[idx][i] += words.select{|x| !x[i].nil?}.length
      @fileInfoHash['ccFileInfoTotal'][i] += words.select{|x| !x[i].nil?}.length
    end
  end
    
    
  def createEachWordList(inText,wordReg,idx)
    @appInfoObjCtl.content['fileInfoWLChoice'] = 0 if @appInfoObjCtl.content['fileInfoWLChoice'].nil?
    case @appInfoObjCtl.content['fileInfoWLChoice']
    when 0
      words = inText.scan(wordReg)
      if Defaults['lemmaCheck']
        words.each do |word|
          @fileInfoHash[idx][NSApp.delegate.lemmaInclude[word]] += 1
          @fileInfoHash['ccFileInfoTotal'][NSApp.delegate.lemmaInclude[word]] += 1
        end
      else
        words.each do |word|
          @fileInfoHash[idx][word] += 1
          @fileInfoHash['ccFileInfoTotal'][word] += 1
        end
      end
    else
      n = @appInfoObjCtl.content['fileInfoWLChoice']
      words = inText.scan(wordReg)
      (words.length - n).times do |i|
        @fileInfoHash[idx][words[i..i+n].join(" ")] += 1
        @fileInfoHash['ccFileInfoTotal'][words[i..i+n].join(" ")] += 1
      end      
    end
  end
  
  def createSelectedWordList(inText,wordReg,idx,wordListHash)
    words = inText.scan(wordReg)
    words.each do |word|
      next if wordListHash[word] == ""
      @fileInfoHash[idx][wordListHash[word]] += 1
      @fileInfoHash['ccFileInfoTotal'][wordListHash[word]] += 1
    end
  end
  
  def createTFIDF(inText,wordReg,idx)
    words = inText.scan(wordReg)
    words.each do |word|
      @foundFileHash[word][idx] = 1
      @fileInfoHash[idx][word] += 1
      @fileInfoHash['ccFileInfoTotal'][word] += 1
    end
  end
  
  def createSelectedTFIDF(inText,wordReg,idx,wordListHash)
    words = inText.scan(wordReg)
    words.each do |word|
      @foundFileHash[word][idx] = 1
      @fileInfoHash[idx][wordListHash[word]] += 1
      @fileInfoHash['ccFileInfoTotal'][wordListHash[word]] += 1
    end
  end
  
  def createKeyGroupList(inText,idx,wordListHash)
    wordListHash.each do |key,val|
      if val.length > 1
        num = inText.scan(val[0]).length - inText.scan(val[1]).length
      else
        num = inText.scan(val[0]).length
      end
      @fileInfoHash[idx][key] += num
      @fileInfoHash['ccFileInfoTotal'][key] += num
    end    
  end
  
  def showGroupingPanel(sender)
    #checkedItems = Array.new
    case Defaults['mode']
    when 0
      if @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|y| y['name']} != @groupingAryCtl.arrangedObjects.map{|y| y['cdbname']}
        @groupingAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@groupingAryCtl.arrangedObjects.length]))
        checkedItems = @fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|y| {'cdbname' => y['name'],'path' => y['path'],'gpSelection' => 0,'labels' => '','labelAry' => []}}
        @groupingAryCtl.addObjects(checkedItems)
      end
    when 1
      if @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.map{|y| y['name']} != @groupingAryCtl.arrangedObjects.map{|y| y['cdbname']}
        @groupingAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@groupingAryCtl.arrangedObjects.length]))
        checkedItems = @fileController.dbListAry.arrangedObjects.select{|x| x['check']}.map{|y| {'cdbname' => y['name'],'path' => y['path'],'gpSelection' => 0,'labels' => '','labelAry' => []}}
        @groupingAryCtl.addObjects(checkedItems)
      end
    end
    @mainWindow.beginSheet(@groupingPanel,completionHandler:Proc.new { |returnCode| })    
  end
  

  def closeGroupingPanel(sender)
    @groupingAryCtl.arrangedObjects.each do |item|
      item['labelAry'] = item['labels'].split(",")
    end
    @mainWindow.endSheet(@groupingPanel)
  end

  
  def showGroupLabellingPanel(sender)
    return if @groupingAryCtl.selectedObjects[0]['gpSelection'] == 1
    @groupLabelAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@groupLabelAryCtl.arrangedObjects.length]))
    case Defaults['mode']
    when 0
      @groupLabelAryCtl.addObjects(NSArray.arrayWithContentsOfFile(@groupingAryCtl.selectedObjects[0]['path']).map{|x| {'filename' => x['filename'], 'label' => ""}})
    when 1
      db = FMDatabase.databaseWithPath(@groupingAryCtl.selectedObjects[0]['path'])
      db.open
        fileList = Array.new
        results = db.executeQuery("SELECT DISTINCT path FROM conc_data")
        while results.next
          items = results.resultDictionary
          fileList << {'filename' => File.basename(items['path']), 'label' => ""}
        end
        @groupLabelAryCtl.addObjects(fileList)
      db.close      
    end
    @groupingPanel.beginSheet(@groupLabellingPanel,completionHandler:Proc.new { |returnCode| })    
    
  end
  
  def closeGroupLabellingPanel(sender)
    @groupingAryCtl.selectedObjects[0]['labels'] = @groupLabelAryCtl.arrangedObjects.map{|x| x['label'].to_s}.join(",")
    @groupingPanel.endSheet(@groupLabellingPanel)
    
  end


  def deleteFileInfoLines(sender)
    @fileInfoTable.undoManager.registerUndoWithTarget(self, selector: "addBackConcLines:", object: [@fileInfoAryCtl.selectedObjects,@fileInfoAryCtl.selectionIndexes])
    @fileInfoAryCtl.removeObjectsAtArrangedObjectIndexes(@fileInfoAryCtl.selectionIndexes)
  end
  
    
  def addBackFileInfoLines(deletedItems)
    @fileInfoAryCtl.insertObjects(deletedItems[0], atArrangedObjectIndexes: deletedItems[1])    
  end
  
  
  
  def copySelectedLines(sender)  ##### not finished #####
    pasteBoard = NSPasteboard.pasteboardWithName(NSGeneralPboard)
    pasteBoard.declareTypes([NSStringPboardType],owner:self)

    case sender.tag
    when 0
      copyText = String.new
      @fileInfoAryCtl.selectedObjects.each do |item|
        if Defaults['concCopyInsertTab']
          copyText << "#{item['kwic'].join("\t")}\n"
        else
          copyText << "#{item['kwic'].join("")}\n"
        end
      end
      pasteBoard.setString(copyText.join("\n"),forType:NSStringPboardType)
    when 1
      copyText = Array.new

      if @currentFIType == 3
        if Defaults['fileInfoCopyLimitCheck']
          if Defaults['fileInfoTableCopyTotalsCheck']
            tableColIDs = @fileInfoTable.tableColumns.map{|x| x.identifier}
            copyText << tableColIDs.map{|x| @fileInfoTable.tableColumnWithIdentifier(x).headerCell.stringValue}
            @fileInfoAryCtl.arrangedObjects.each do |item|
              copyText << tableColIDs.map{|x| item[x]}
            end
          else
            tableColIDs = @fileInfoTable.tableColumns.map{|x| x.identifier}.delete_if{|x| x == 'ccFITotalFreq'}
            copyText << tableColIDs.map{|x| @fileInfoTable.tableColumnWithIdentifier(x).headerCell.stringValue}
            tableColIDs[0] = "ccFIGroup"
            @fileInfoAryCtl.arrangedObjects.each do |item|
              next if item['ccFIGroup'] == " TOTAL"
              copyText << tableColIDs.map{|x| item[x]}
            end
          end
        else
          if Defaults['fileInfoTableCopyTotalsCheck']
            copyText << ["Group","Total"] + @itemOrder
            @fileInfoAryCtl.arrangedObjects.each do |item|
              eachLine = Array.new
              eachLine << item['ccFIGroup']
              eachLine << item['ccFITotalFreq']
              eachLine.concat((1..@itemOrder.length).to_a.map{|x| item["ccFIItem#{x}"]})
              copyText << eachLine
            end
          else
            copyText << ["Group"] + @itemOrder
            @fileInfoAryCtl.arrangedObjects.each do |item|
              next if item['ccFIGroup'] == ' TOTAL'
              eachLine = Array.new
              eachLine << item['ccFIGroup']
              eachLine.concat((1..@itemOrder.length).to_a.map{|x| item["ccFIItem#{x}"]})
              copyText << eachLine
            end
          end
        end
      elsif @currentFIType == 0 || Defaults['fileInfoCopyLimitCheck']
        copyText << @fileInfoTable.tableColumns.map{|x| x.headerCell.stringValue}
        @fileInfoAryCtl.arrangedObjects.each do |item|
          copyText << @fileInfoTable.tableColumns.map{|x| item[x.identifier]}
        end
      else
        case @currentFIType
        when 1
          copyText << ["Group","Total"] + @itemOrder
        when 2
          copyText << ["Group","Token"] + @itemOrder
        end
        @fileInfoAryCtl.arrangedObjects.each do |item|
          eachLine = Array.new
          eachLine << item['ccFIGroup']
          eachLine << item['ccFITotalFreq']
          eachLine.concat((1..@itemOrder.length).to_a.map{|x| item["ccFIItem#{x}"]})
          copyText << eachLine
        end
      end
      copyText = copyText.transpose if Defaults['fileInfoTableExportTransposeCheck']
    end
    pasteBoard.setString(copyText.join("\n"),forType:NSStringPboardType)
    
  end


  
  def numberOfRowsInTableView(tableView)
    case tableView
    when @importWLTable
      @importWLAryCtl.arrangedObjects.length
    end
	end
		

	def tableView(tableView,objectValueForTableColumn:col,row:row)
    case col
    when tableView.tableColumnWithIdentifier('id')
      row + 1
    end
	end
  
  
  
  def sheetDidEnd(sheet, returnCode: returnCode, contextInfo: info)
    sheet.close
  end

  def alertDidEnd(alert, returnCode: returnCode, contextInfo: info)
    alert.window.orderOut(nil)
  end

  def noFileAlertDidEnd(alert, returnCode: returnCode, contextInfo: info)
    alert.window.orderOut(nil)
    @mainTab.selectTabViewItemAtIndex(0)
  end

  def noGroupingAlertDidEnd(alert, returnCode: returnCode, contextInfo: info)
    alert.window.orderOut(nil)
  end
  
end
