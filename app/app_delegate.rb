class AppDelegate
  extend IB

  outlet :window
  outlet :mainTab
  outlet :progressBar
  outlet :appInfoObjCtl
  outlet :modeSwitch
  outlet :inputText

  outlet :concSortSelect
  outlet :concTableFrame
  outlet :concTable
  outlet :concContextView  
  
  outlet :plotBtn
  
  outlet :fileController
  
  outlet :fileController
  outlet :concController
  
  outlet :concExportEncodingView
  outlet :encodingView
  #outlet :concResultAry
  outlet :concOpenOptionView
  
  outlet :fileSplitView
    
  attr_accessor :prefController
  
  attr_accessor :currentConcScope
  attr_accessor :currentConcMode
  attr_accessor :modeSwitch, :currentCDs
  attr_accessor :currentGroups, :changeFlags
  attr_accessor :wcWindows
  attr_accessor :currentWL, :concWindows
  

  def awakeFromNib
    userDefaultFilePath = NSBundle.mainBundle.pathForResource("UserDefaults",ofType:"plist")
    userDefaultValues = NSDictionary.dictionaryWithContentsOfFile(userDefaultFilePath)
    NSUserDefaults.standardUserDefaults.registerDefaults(userDefaultValues)
    @fileManager = NSFileManager.defaultManager
    @fileManager.createDirectoryAtPath(CCFolderPath,attributes:nil) if !@fileManager.fileExistsAtPath(CCFolderPath)
    @fileManager.createDirectoryAtPath("#{CCFolderPath}/cdlists",attributes:nil) if !@fileManager.fileExistsAtPath("#{CCFolderPath}/cdlists")
    @fileManager.createDirectoryAtPath("#{CCFolderPath}/corpus",attributes:nil) if !@fileManager.fileExistsAtPath("#{CCFolderPath}/corpus")
    @fileManager.createDirectoryAtPath("#{CCFolderPath}/lkslist",attributes:nil) if !@fileManager.fileExistsAtPath("#{CCFolderPath}/lkslist")
    @fileManager.createDirectoryAtPath("#{CCFolderPath}/wchandler",attributes:nil) if !@fileManager.fileExistsAtPath("#{CCFolderPath}/wchandler")
    @fileManager.createDirectoryAtPath("#{CCFolderPath}/temp",attributes:nil) if !@fileManager.fileExistsAtPath("#{CCFolderPath}/temp")

    @progressBar.setDisplayedWhenStopped(false)
    @progressBar.setUsesThreadedAnimation(true)
    @openedEditorDoc = []
    @openedPDFDoc = []
    @concWindows = []
    @concPlots = []
    @wcWindows = []
    @currentResultMode = ["Simple/File", "Simple/Text", "Advanced/File", "Advanced/Database"]
    @currentResultScope = ["File","Paragraph","Sentence"]
    @modeSwitch.setSegmentCount(2)

  end
  
  def applicationDidFinishLaunching(notification)

    @appInfoObjCtl.content["encoding"] = 0
    @appInfoObjCtl.content["concLeftContextSpan"] = 5
    @appInfoObjCtl.content["concRightContextSpan"] = 14
    @appInfoObjCtl.content["toolSelection"] = 1
    @appInfoObjCtl.content["concLeftExcludeSpan"] = 5
    @appInfoObjCtl.content["concRightExcludeSpan"] = 14
    @appInfoObjCtl.content['concSearchMode'] = 0
    @appInfoObjCtl.content['concSortOrder'] = [11,12,13,21]
    @appInfoObjCtl.content['databaseEditorEnable'] = Defaults['scopeOfContextChoice'] != 2 ? 1 : 0
    @appInfoObjCtl.content['databaseEditorHide'] = Defaults['mode'] == 1 && Defaults['corpusMode'] == 1 ? 0 : 1
    @appInfoObjCtl.content['databaseEditorEnable'] = Defaults['scopeOfContextChoice'] != 2 ? 1 : 0
    @appInfoObjCtl.content['databaseEditorHide'] = 1
    @appInfoObjCtl.content['concOpenChoice'] = 0
    @appInfoObjCtl.content['concInfoSecLength'] = {}
    @appInfoObjCtl.content['concSortChoice'] = false
    
    @appInfoObjCtl.content['encoding'] = 0
        
    Defaults['sortOrder'].each do |soVal|
      @concSortSelect.addItemWithTitle(soVal['sortOrder'])
    end
    
    @appInfoObjCtl.content['concSortSelect'] = Defaults['sortOrder'][0]['sortOrder']
    @appInfoObjCtl.content['concSort1'] = 10
    @appInfoObjCtl.content['concSort2'] = 10
    @appInfoObjCtl.content['concSort3'] = 10
    @appInfoObjCtl.content['concSort4'] = 10    
    @appInfoObjCtl.content['concCorpusSelection'] = Defaults['concCorpusSelection'].to_i
    @appInfoObjCtl.content['concDatabaseSelection'] = Defaults['concDatabaseSelection'].to_i
    
    @appInfoObjCtl.content['fileinfoKWGroupAutoIDCheck'] = false
    @windowState = 1
    
    if Defaults['corpusMode'] == 0
      @modeSwitch.setLabel("Text",forSegment:1)
      #@modeSwitch.setLabel("",forSegment:2)
      #@modeSwitch.setEnabled(false,forSegment:2)
    end


    @fileController.corpusListAry.addObjects(NSMutableArray.arrayWithContentsOfFile("#{CDListFolderPath}/corpuslist")) if NSFileManager.defaultManager.fileExistsAtPath("#{CDListFolderPath}/corpuslist")
    @fileController.dbListAry.addObjects(NSMutableArray.arrayWithContentsOfFile("#{CDListFolderPath}/dblist")) if NSFileManager.defaultManager.fileExistsAtPath("#{CDListFolderPath}/dblist")
    @fileController.indexedDBListAry.addObjects(NSMutableArray.arrayWithContentsOfFile("#{CDListFolderPath}/idxdblist")) if NSFileManager.defaultManager.fileExistsAtPath("#{CDListFolderPath}/idxdblist")
    
    
    2.times do |i|
      newSelection = []
      [@fileController.corpusListAry,@fileController.dbListAry][i].arrangedObjects.each do |item|
        newSelection << {'name' => item['name'], 'path' => item['path']} if item['check'] == true
      end

      newSelection.insert(0,{'name' => "All"}) if newSelection.length > 1
      [@fileController.selectedCorpusAryCtl,@fileController.selectedDatabaseAryCtl][i].addObjects(newSelection)
    end
    
    @currentGroups = Array.new(2)
    @changeFlags = [[0,0,0,0,0],[0,0,0]]

    listItems = ListItemProcesses.new
    listItems.stopWordPrepare if Defaults['wchStopWordCheck']
    listItems.skipCharPrepare if Defaults['wchSkipCharCheck']
    listItems.includeWordPrepare if Defaults['wchIncludeWordCheck']
    listItems.multiWordPrepare if Defaults['wchMultiWordCheck']
    #listItems.eosWordPrepare if Defaults['scopeOfContextChoice'] == 2
    listItems.lemmaPrepare if Defaults['lemmaCheck']
    listItems.kwgPrepare if Defaults['kwgCheck']
    listItems.spvPrepare if Defaults['spVarCheck']
    listItems.charReplacePrepare if Defaults['replaceCharCheck']
    listItems.includeAsPartWordPrepare if Defaults['qouteIncludeCheck'] || Defaults['hyphenIncludeCheck'] || (Defaults['othersIncludeCheck'] && Defaults['partOfWordChars'] != "")

    Defaults['sortOrder'].each do |soVal|
      @concSortSelect.addItemWithTitle(soVal['sortOrder'])
    end

    @window.makeKeyAndOrderFront(nil)
    
  end
  
  def localizeString(string)
    NSBundle.mainBundle.localizedStringForKey(string, value: string, table: nil)
  end
  

  def windowDidBecomeKey(notification)
    if notification.object == @window
      self.concTableSizeAdjust
      self.refreshWindow
      @concContextView.setFont(NSFont.fontWithName("Lucida Grande", size: Defaults['concContextViewFontSize'])) 
    end
  end


  def changeMode(sender)
    self.refreshWindow
  end
  
  
  
  def refreshWindow
    case Defaults['corpusMode']
    when 0
      @concTable.tableColumnWithIdentifier("corpus").setHidden(true)
    when 1
      @concTable.tableColumnWithIdentifier("corpus").setHidden(false)
      case Defaults['mode']
      when 0
        @concTable.tableColumnWithIdentifier('corpus').headerCell.setStringValue("Corpus")
      when 1
        @concTable.tableColumnWithIdentifier('corpus').headerCell.setStringValue("Database")
      end
    end
    if Defaults['mode'] == 1 && Defaults['corpusMode'] == 0
      @concTable.tableColumnWithIdentifier("filename").setHidden(true)
    else
      @concTable.tableColumnWithIdentifier("filename").setHidden(false)
    end
  end


  def toolChange(sender)
    @mainTab.selectTabViewItemAtIndex(sender.tag)
  end


  def concTableSizeAdjust
    if Defaults['contextExcludeCheck'] == true && @concTableHeightCheck.to_i == 0
      @concTableFrame.setFrameSize([@concTableFrame.frame.size.width,@concTableFrame.frame.size.height - 22])
      @concTableHeightCheck = 1
    elsif Defaults['contextExcludeCheck'] == false && @concTableHeightCheck.to_i == 1
      @concTableFrame.setFrameSize([@concTableFrame.frame.size.width,@concTableFrame.frame.size.height + 22])
      @concTableHeightCheck = 0
    end
  end



  def showPrefWindow(sender)
    @prefWindow = Preferences.new if @prefWindow.nil?
    @prefWindow.showWindow(self)
  end


  def showConcFontPanel(sender)
    @concFontPanel = ConcFontManagerController.new if @concFontPanel.nil?
    @concFontPanel.showWindow(self)
  end

  def showWCHandlingWindow(sender)
    @wcHandlerWindow = WordCharHandlingController.new if @wcHandlerWindow.nil?
    @wcHandlerWindow.showWindow(self)
  end

  def showReplaceCharsWindow(sender)
    @replaceCharsPanel = ReplaceCharController.new if @replaceCharsPanel.nil?
    @replaceCharsPanel.showWindow(self)
  end

  def showLKWSPVWindow(sender)
    @lemmaKWGSPVWindow = LemmaKYGSPVarListController.new if @lemmaKWGSPVWindow.nil?
    @lemmaKWGSPVWindow.showWindow(self)
  end
  
  
  def showConcResultWindow(sender)
    if (existPlot = @concWindows.select{|x| x[0] == @concController.concSearchEndTime}).length > 0
      existPlot[0][1].window.makeKeyAndOrderFront(nil)
    else
      concResultWindow = ConcResultController.new
      concResultWindow.window.setTitle("KWIC of '#{@appInfoObjCtl.content['concSearchWord']}'")
      concResultWindow.concResultAry = @concController.concResultAry
      concResultWindow.fileController = @fileController
      concResultWindow.appInfoObjCtl.content['concSortOrder'] = @appInfoObjCtl.content['concSortOrder']

      Defaults['sortOrder'].each do |soVal|
        concResultWindow.concSortOrderChoices.addItemWithTitle(soVal['sortOrder'])
      end
      
      
      if Defaults['corpusMode'] == 0
        concResultWindow.concTable.tableColumnWithIdentifier('corpus').setHidden(true)
      else
        concResultWindow.concTable.tableColumnWithIdentifier('corpus').setHeaderCell(NSTableHeaderCell.alloc.initTextCell(@concTable.tableColumnWithIdentifier('corpus').headerCell.stringValue))
      end
      if Defaults['corpusMode'] == 0 && Defaults['mode'] == 1
        concResultWindow.concTable.tableColumnWithIdentifier('filename').setHidden(true)
      else
        concResultWindow.concTable.tableColumnWithIdentifier('filename').setHeaderCell(NSTableHeaderCell.alloc.initTextCell(@concTable.tableColumnWithIdentifier('filename').headerCell.stringValue))
      end

      concResultWindow.concTable.tableColumnWithIdentifier('kwic').setHeaderCell(NSTableHeaderCell.alloc.initTextCell(@concTable.tableColumnWithIdentifier('kwic').headerCell.stringValue))

      concResultWindow.encodingChoice.selectItemAtIndex(@appInfoObjCtl.content["encoding"])
      concResultWindow.concSearchWord = @appInfoObjCtl.content['concSearchWord']
      concResultWindow.concContextWord = @appInfoObjCtl.content['concContextWord']
      concResultWindow.concExcludeWord = @appInfoObjCtl.content['concExcludeWord']
      concResultWindow.searchEndTime = @concController.concSearchEndTime
      concResultWindow.currentConcMode = @currentConcMode
      concResultWindow.currentConcScope = @currentConcScope
      concResultWindow.appInfoObjCtl.content['concSortChoice'] = @appInfoObjCtl.content['concSortChoice']
      concResultWindow.appInfoObjCtl.content['concSortSelect'] = @appInfoObjCtl.content['concSortSelect']
      concResultWindow.appInfoObjCtl.content['concSort1'] = @appInfoObjCtl.content['concSort1']
      concResultWindow.appInfoObjCtl.content['concSort2'] = @appInfoObjCtl.content['concSort2']
      concResultWindow.appInfoObjCtl.content['concSort3'] = @appInfoObjCtl.content['concSort3']
      concResultWindow.appInfoObjCtl.content['concSort4'] = @appInfoObjCtl.content['concSort4']
      concResultWindow.appInfoObjCtl.content['encoding'] = @appInfoObjCtl.content['encoding']
      

      concResultWindow.showWindow(self)
      @concWindows << [@concController.concSearchEndTime,concResultWindow]
    end
  end
  
  
  
  
  
  def openSelectedFileInFinder(item)

    workspace = NSWorkspace.sharedWorkspace
    begin
      workspace.selectFile(item['path'],inFileViewerRootedAtPath:nil)
    rescue
      alert = NSAlert.alertWithMessageText("Selected file '#{item['filename']}' is not found.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"")
    

      alert.beginSheetModalForWindow(@window,completionHandler:Proc.new { |returnCode| })
      return
    end
  end


  def openSelectedFileWithApp(item)
    if NSFileManager.defaultManager.fileExistsAtPath(item['path']) == false

    end
    workspace = NSWorkspace.sharedWorkspace
    begin
      workspace.openFile(item['path'],withApplication:Defaults[AssignedApp[File.extname(item['path']).downcase]])
    rescue
      alert = NSAlert.alertWithMessageText("Selected file '#{item['filename']}' is not found.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"")


      alert.beginSheetModalForWindow(@window,completionHandler:Proc.new { |returnCode| })
      return
    end
  end


  def fileNotFoundWarning(filename)
    alert = NSAlert.alertWithMessageText("The selected file '#{File.basename(filename)}' was not found.",
                                        defaultButton:"OK",
                                        alternateButton:nil,
                                        otherButton:nil,
                                        informativeTextWithFormat:"Please check the file.")
    return if alert.runModal == 1
  end
  
  
  
  
  def saveResults(sender)
    return if !@window.isKeyWindow

    panel = NSSavePanel.savePanel

    case @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
    when 1
      return if @concResultAry.length == 0
      msg = "Select a folder and name the file to save the Concordance result."
      ext = [:concdata]
    else
      return
    end

    panel.setMessage(msg)
    panel.setCanSelectHiddenExtension(true)
    panel.setAllowedFileTypes(ext)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['exportDefaultFolder']))
    panel.beginSheetModalForWindow(@window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        @progressBar.startAnimation(nil)
        case @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
        when 1
          aryToSave = @concResultAry.mutableCopy
          aryToSave.unshift({'currentMode' => @currentConcMode, 'currentScope' => @currentConcScope, 'searchWord' => @concController.concCurrentSearchWords.map{|x| x[0]}.join(","), 'contextWord' => @concController.concCurrentSearchWords.map{|x| x[1].to_s}.join(","), 'exclWord' => @concController.concCurrentSearchWords.map{|x| x[2].to_s}.join(","), 'currentPlotChoice' => @appInfoObjCtl.content['currentPlotChoice'].to_i, 'concInfoSecLength' => @appInfoObjCtl.content['concInfoSecLength']})
          aryToSave.writeToFile(panel.filename, atomically: true)
        end
        @progressBar.stopAnimation(nil)
      end
    })
  end



  def openSavedResults(sender)
    tool = @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
    return if tool == 0

    panel = NSOpenPanel.openPanel
    aryExistsFlag = 0
    case tool
    when 1
      msg = "Select a Concord result file."
      ext = [:concdata]
      aryExistsFlag = 1 if @concResultAry.length > 0
      panel.setAccessoryView(@concOpenOptionView)
    else
      return
    end

    if aryExistsFlag == 1 && tool != 1
      alert = NSAlert.alertWithMessageText("Are you sure you want to open a saved result?",
                                          defaultButton:"Yes",
                                          alternateButton:nil,
                                          otherButton:"No",
                                          informativeTextWithFormat:"The current results on the table will be gone.")
      alert.buttons[1].setKeyEquivalent("\e")
      userChoice = alert.runModal
      return if userChoice == -1
    end


  	panel.setTitle(msg)
  	panel.setCanChooseDirectories(false)
  	panel.setCanChooseFiles(true)
  	panel.setAllowsMultipleSelection(false)
    panel.setAllowedFileTypes(ext)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['exportDefaultFolder']))
    panel.beginSheetModalForWindow(@window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        if @concResultAry.length != 0# && ((@mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem) == 1 && @appInfoObjCtl.content['concOpenChoice'] == 0) || (@mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem) == 2 && @wcController.wcAryCtl[@appInfoObjCtl.content['saveTableChoice']].arrangedObjects.length > 0) || (@mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem) == 4 && @clustController.clustAryCtl[@appInfoObjCtl.content['saveTableChoice']].arrangedObjects.length > 0))
          alert = NSAlert.alertWithMessageText("Are you sure you want to open a saved result?",
                                              defaultButton:"Yes",
                                              alternateButton:nil,
                                              otherButton:"No",
                                              informativeTextWithFormat:"The current results on the table will be gone.")
          alert.buttons[1].setKeyEquivalent("\e")
          userChoice = alert.runModal
          break if userChoice == -1
        end
        @progressBar.startAnimation(nil)
        case @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
        when 1
          resultAry = NSMutableArray.arrayWithContentsOfFile(panel.filename)
          modeScope = resultAry[0].mutableCopy
          resultAry.removeObjectAtIndex(0)
          case @appInfoObjCtl.content['concOpenChoice']
          when 0
            @concResultAry.removeObjectsAtIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@concResultAry.length])) if @concResultAry.length > 0
            @currentConcMode = modeScope['currentMode']
            @currentConcScope = modeScope['currentScope']
            @appInfoObjCtl.content['concSearchWord'] = modeScope['searchWord']
            @appInfoObjCtl.content['currentPlotChoice'] = modeScope['currentPlotChoice']
            @appInfoObjCtl.content['concInfoSecLength'] = modeScope['concInfoSecLength']
          
            if modeScope['contextWord'] == ""
              @appInfoObjCtl.content.removeObjectForKey('concContextWord') if @appInfoObjCtl.content['concContextWord']
            else
              @appInfoObjCtl.content['concContextWord'] = modeScope['contextWord']
            end
            if modeScope['contextWord'] == ""
              @appInfoObjCtl.content.removeObjectForKey('concExcludeWord') if @appInfoObjCtl.content['concExcludeWord']
            else
              @appInfoObjCtl.content['concExcludeWord'] = modeScope['exclWord']
            end
            @plotBtn.setEnabled(false) if !@plotBtn.isHidden && @plotBtn.isEnabled
          when 1,2
            if @concResultAry.length != 0 && (@currentConcMode != modeScope['currentMode'] || @currentConcScope != modeScope['currentScope'] || resultAry[0]['kwic'][0].length != @concResultAry[0]['kwic'][0].length || @appInfoObjCtl.content['currentPlotChoice'] != modeScope['currentPlotChoice'])
              alert = NSAlert.alertWithMessageText("Are you sure you want to proceed?",
                                                  defaultButton:"Yes",
                                                  alternateButton:nil,
                                                  otherButton:"No",
                                                  informativeTextWithFormat:"The saved data file was created with different settings.")
              alert.buttons[1].setKeyEquivalent("\e")
              userChoice = alert.runModal
              if userChoice == -1
                @progressBar.stopAnimation(nil)
                break 
              end
            end
            @appInfoObjCtl.content['concInfoSecLength'].merge!(modeScope['concInfoSecLength'])
          
            if @appInfoObjCtl.content['concOpenChoice'] == 2
              newLevel = @concResultAry.map{|x| x['searchLevel']}.max + 1
              resultAry.each do |item|
                item['searchLevel'] = newLevel
              end
            end
          end
          @concResultAry = resultAry
          @concController.concSearchEndTime = Time.now
          @concController.resortConcResult(nil) if @appInfoObjCtl.content['concOpenChoice'] == 1 || @appInfoObjCtl.content['concOpenChoice'] == 2
        end
        @progressBar.stopAnimation(nil)
      end
    })
  end



  def exportResult(sender)

    case @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
    when 1
      return if @concResultAry.length == 0
      msg = "Select a folder and name the file to export Concordance results."
      ext = Defaults['exportKeepFontInfo'] ? [:rtf] : [:txt]
      exportAccView = @concExportEncodingView
    else
      return
    end

    panel = NSSavePanel.savePanel

    panel.setMessage(msg)
    panel.setCanSelectHiddenExtension(true)
    panel.setAccessoryView(exportAccView)
    panel.setAllowedFileTypes(ext)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['exportDefaultFolder']))
    panel.beginSheetModalForWindow(@window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        case @mainTab.indexOfTabViewItem(@mainTab.selectedTabViewItem)
        when 1
          self.concExportProcess(panel.filename)
        end

      end
    })
  end

  def changeExportFileType(sender)
    sender.window.setAllowedFileTypes(sender.state == 1 ? [:rtf] : [:txt])
  end



  def concExportProcess(exportFilename)
    @progressBar.startAnimation(nil)
    outText = []
    outText << "Concordance Output: #{NSDate.date.description.sub(/ [+-]\d+$/,"")}"
    searchWordInfo = ""
    searchWordInfo += "Search Word: #{@appInfoObjCtl.content['concSearchWord'].to_s}" if !@appInfoObjCtl.content['concSearchWord'].nil?
    searchWordInfo += "\tContext Word: #{@appInfoObjCtl.content['concContextWord'].to_s}" if !@appInfoObjCtl.content['concContextWord'].nil?
    searchWordInfo += "\tContext Exclude Word: #{@appInfoObjCtl.content['concExcludeWord'].to_s}" if Defaults['contextExcludeCheck'] && !@appInfoObjCtl.content['concExcludeWord'].nil?
    outText << searchWordInfo
    outText << ""
    if Defaults['corpusMode'] == 1
      case Defaults['mode']
      when 0
        outText << "Corpora: #{@fileController.corpusListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")}"
      when 1
        outText << "Database: #{@fileController.dbListAry.arrangedObjects.select{|x| x['check']}.map{|x| x['name']}.join(", ")}"
      end
    end
    if Defaults['exportKeepFontInfo']
      colorPosAdjust1 = Defaults['concExportInsertTab'] ? 1 : 0
      colorPosAdjust2 = Defaults['concExportInsertTab'] ? 2 : 0
      initLine = "\tKWIC"
      initLine += "\tFile Name" if Defaults['exportFilename'] && !(Defaults['corpusMode'] == 0 && Defaults['mode'] == 1)
      initLine += "\tCorpus/Database" if Defaults['concExportCDName'] && Defaults['corpusMode'] == 1
      outText << initLine
      outAttrText = NSMutableAttributedString.alloc.initWithString(outText.join("\n"))
      @concResultAry.each_with_index do |item,idx|
        if Defaults['concExportInsertTab']
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join("\t"),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        else
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
        end
        if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
          concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [item['kwic'][0].length + colorPosAdjust1,item['kwic'][1].length])
        end
        if Defaults['concExportContextColor']
          @appInfoObjCtl.content['concSortOrder'].each_with_index do |orderPos,idx|
            if orderPos > 10
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [item['sortItems'][orderPos][1][0] + colorPosAdjust2,item['sortItems'][orderPos][1][1]])
            else
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: item['sortItems'][orderPos][1])
            end
          end
        end
        if Defaults['concExportContextStyle'] && !item['contextMatch'].nil?
          if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
            item['contextMatch'].each do |contextMatch|
              concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: contextMatch[1])
            end
    		  else
            item['contextMatch'].each do |contextMatch|
              concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: contextMatch[1])
            end
  		    end
        end
        concLine.insertAttributedString(NSAttributedString.alloc.initWithString("\n#{idx+1}\t"), atIndex: 0)
        concLine.appendAttributedString(NSAttributedString.alloc.initWithString("\t#{item['filename']}")) if Defaults['exportFilename'] && !item['filename'].nil?
        concLine.appendAttributedString(NSAttributedString.alloc.initWithString("\t#{item['corpus']}")) if Defaults['concExportCDName'] && !item['corpus'].nil?

        outAttrText.appendAttributedString(concLine)
      end
      outAttrText.RTFFromRange([0,outAttrText.length], documentAttributes: nil).writeToFile(exportFilename, atomically: true)
    else
      if Defaults['concExportInsertTab']
        initLine = "\tLeft Context\tKey\tRight Context"
      else
        initLine = "\tKWIC"
      end
      if Defaults['concExportContextWords']
        if Defaults['concExportContextLeftChoice'] < 10
          initLine += "\t#{["L10", "L9", "L8", "L7", "L6", "L5", "L4", "L3", "L2", "L1"][Defaults['concExportContextLeftChoice']..9].join("\t")}"
        end
        if Defaults['concExportContextRightChoice'] < 10
          initLine += "\t#{["R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10"][0..Defaults['concExportContextRightChoice']].join("\t")}"
        end
      end

      #initLine += "\tL10\tL9\tL8\tL7\tL6\tL5\tL4\tL3\tL2\tL1\tR1\tR2\tR3\tR4\tR5\tR6\tR7\tR8\tR9\tR10" if Defaults['concExportContextWords']
      initLine += "\tFile Name" if Defaults['exportFilename'] && !(Defaults['corpusMode'] == 0 && Defaults['mode'] == 1)
      initLine += "\tCorpus/Database" if Defaults['concExportCDName'] && Defaults['corpusMode'] == 1

      outText << initLine
      @concResultAry.each_with_index do |item,idx|
        outLine = "#{idx+1}\t"
        kwicOut = "\"#{item['kwic'].join("")}\""
        if Defaults['concExportInsertTab']
          kwicOut = "\"#{item['kwic'].join("\"\t\"")}\""
        else
          kwicOut = "\"#{item['kwic'].join("")}\""
        end
        outLine += kwicOut
        if Defaults['concExportContextWords']
          contextWordsAry = item['sortItems'].map{|x| x[0]}
          if Defaults['concExportContextRightChoice'] == 10
            outLine += "\t#{contextWordsAry[Defaults['concExportContextLeftChoice']..9].join("\t")}"
          else
            outLine += "\t#{(contextWordsAry[Defaults['concExportContextLeftChoice']..9] + contextWordsAry[11..(Defaults['concExportContextRightChoice']+11)]).join("\t")}"
          end
        end
        outLine += "\t#{item['filename']}" if Defaults['exportFilename'] && !item['filename'].nil?
        outLine += "\t#{item['corpus']}" if Defaults['concExportCDName'] && !item['corpus'].nil?
        outText << outLine
      end
      outText.join("\n").writeToFile(exportFilename, atomically: true, encoding: TextEncoding[@appInfoObjCtl.content['encoding']], error: nil)
    end
    @progressBar.stopAnimation(nil)
  end


  def wcExportProcess(exportFilename)
    @progressBar.startAnimation(nil)

    outText = []
    tableID = @appInfoObjCtl.content['saveTableChoice']
    option = @appInfoObjCtl.content['wcExportOptions']
    wcAry = @wcController.wcAryCtl[tableID].arrangedObjects


    case option
    when 0
      outText << "Word List Output:  #{NSDate.date.description.sub(/ [+-]\d+$/,"")}\n#{@appInfoObjCtl.content[@wcController.wcResultInfo[tableID]]}"
      if @currentWCMode[tableID][1] == 1
        outText << "#{@fileController.cdLabel[@currentWCMode[tableID][0]]}: #{@currentWCCDs[tableID]}"
      end
      outText << ""
      wcLabels = "\t#{@wcController.wcTable[tableID].tableColumnWithIdentifier('word').headerCell.stringValue}\tFrequency\tProportion"
      outText << wcLabels
      outText += @wcController.wcAryCtl[tableID].arrangedObjects.map{|x| "#{x['rank']}\t#{x['word']}\t#{x['freq']}\t#{sprintf("%.2f%",x['prop'].to_f*100)}"}
    when 1
      outText += @wcController.wcAryCtl[tableID].arrangedObjects.map{|x| "#{x['word']}\t#{x['freq']}"}
    when 2
      outText << "Word List Output:  #{NSDate.date.description.sub(/ [+-]\d+$/,"")}\t#{@appInfoObjCtl.content[@wcResultInfo[tableID]]}"
      if @currentWCMode[tableID][1] == 1
        outText << "#{@fileController.cdLabel[@currentWCMode[tableID][0]]}: #{@currentWCCDs[tableID]}"
      end
      outText << "\t#{@wcController.wcTable[tableID].tableColumnWithIdentifier('word').headerCell.stringValue}\tFrequency\tProportion\tIn File\tIn Corpus\t#{@wcController.wcTable[tableID].tableColumnWithIdentifier('stats').headerCell.stringValue}\tLemma Words\tContent Words"

      outText += @wcController.wcAryCtl[tableID].arrangedObjects.map{|x| "#{x['rank']}\t#{x['word']}\t#{x['freq']}\t#{sprintf("%.2f%",x['prop'].to_f)}\t#{x['inFile'].to_s}\t#{x['inCorpus'].to_s}\t#{sprintf("%.3f",x['stats'].to_f)}\t#{x['lemma'].to_s}\t#{x['contentWords'].to_s}"}
    end
    outText.join("\n").writeToFile(exportFilename, atomically: true, encoding: TextEncoding[@appInfoObjCtl.content['encoding']], error: nil)

    @progressBar.stopAnimation(nil)

  end

  
  
  def revertToDefaultWindowSize(sender) 
    currentFrame = @mainWindow.frame
    currentFrame.origin.y = currentFrame.origin.y + (currentFrame.size.height - 600)
    currentFrame.size.width = 1000
    currentFrame.size.height = 600
    @mainWindow.setFrame(currentFrame,display:true)
    @fileSplitView.setPosition(500.0,ofDividerAtIndex:0)
    @wcSplitView.setPosition(500.0,ofDividerAtIndex:0)
    @clstSplitView.setPosition(500.0,ofDividerAtIndex:0)
  end


  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end


  def applicationShouldTerminate(notification)
    @window.performClose(nil) if @windowState == 1
    if @windowState == 1
      NSTerminateCancel
    else
      NSTerminateNow
    end
  end

  def windowShouldClose(notification)
    case notification
    when @window
      alert = NSAlert.alertWithMessageText("Are you sure you want to quit CasualConc?",
                                          defaultButton:"Yes",
                                          alternateButton:nil,
                                          otherButton:"No",
                                          informativeTextWithFormat:"All the data on tables will be gone.")
      alert.buttons[1].setKeyEquivalent("\e")
      userChoice = alert.runModal
      case userChoice
      when -1
        NSTerminateCancel
        @windowState = 1
        false
      when 1
        @fileController.corpusListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/corpuslist", atomically: true)
        @fileController.dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)
        @fileController.indexedDBListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/idxdblist", atomically: true)
        Defaults['concCorpusSelection'] = @appInfoObjCtl.content['concCorpusSelection']
        Defaults['concDatabaseSelection'] = @appInfoObjCtl.content['concDatabaseSelection']
        @windowState = 0
        true
      end
    else
      true
    end
  end
end
