# Preferences.rb
# CasualConc
#
# Created by Yasu on 10/11/19.
# Copyright 2010 Yasu Imao. All rights reserved.


class Preferences < NSWindowController
  extend IB
  
  outlet :prefTab
  outlet :selectFileTypesPanel
  outlet :selectAppForFilePanel
  outlet :sortOrderPanel
  outlet :sortOrder1
  outlet :sortOrder2
  outlet :sortOrder3
  outlet :sortOrder4
  outlet :sortOrderAryCtl
  outlet :sortOrderTable 
  outlet :coloringTable
  outlet :sectionTagsAryCtl
  outlet :ignoreStringsAryCtl
  
  attr_accessor :initialChecks
  
  def windowNibName
    "Preferences"
  end
  
  
  def awakeFromNib
    @assignedAppTypes = ['appForPt','appForRt','appForWeb','appForPdf','appForMsWord','appForOpenOffice']
    @fileTypesForApp = ['Plain Text','Rich Text','Web','PDF','MS Word','Open Office']
    @defaultFolderTypes = ['corpusDefaultFolder','databaseDefaultFolder','exportDefaultFolder']
    @dataTypeForFolder = ['Corpus Files','Database Files','Export Results']
    @initialGroup = [0,[0,0,0]]
    @initialChecks = [[0,0,0,0],[0,0,0],0,[0,0,0]]
  end
  
  def changeCorpusMode(sender)
    if Defaults['corpusMode'] == 0
      NSApp.delegate.modeSwitch.setLabel("Text",forSegment:1)
      #NSApp.delegate.modeSwitch.setLabel("",forSegment:2)
      #NSApp.delegate.modeSwitch.setEnabled(false,forSegment:2)
      #NSApp.delegate.modeSwitch.setSelectedSegment(0) if NSApp.delegate.modeSwitch.selectedSegment == 2
    else
      NSApp.delegate.modeSwitch.setLabel("Database",forSegment:1)
      #NSApp.delegate.modeSwitch.setLabel("Indexed Database",forSegment:2)
      #NSApp.delegate.modeSwitch.setEnabled(true,forSegment:2)
    end
  end
  
  
  def prefTabChange(sender)
    @prefTab.selectTabViewItemAtIndex(sender.tag)
  end
    
  def openSelectAcceptFileTypes(sender)
    self.window.beginSheet(@selectFileTypesPanel,completionHandler:Proc.new { |returnCode| })    
  end
  

  def closeSelectAcceptFileTypes(sender)
    self.window.endSheet(@selectFileTypesPanel)
  end
  

  def openSelectAppForFile(sender)
    self.window.beginSheet(@selectAppForFilePanel,completionHandler:Proc.new { |returnCode| })    
  end
  
  def closeSelectAppForFile(sender)
    self.window.endSheet(@selectAppForFilePanel)
  end


  def openSortOrderPresetEditor(sender)
    @sortOrderPanel.makeKeyAndOrderFront(nil)
  end
  
  def addSortOrder(sender)
    sortOrder = "#{@sortOrder1.titleOfSelectedItem}-#{@sortOrder2.titleOfSelectedItem}-#{@sortOrder3.titleOfSelectedItem}-#{@sortOrder4.titleOfSelectedItem}"
    @sortOrderAryCtl.addObject({'sortOrder' => sortOrder})
    NSApp.delegate.concSortSelect.addItemWithTitle(sortOrder)
  end
  
  def removeSortOrder(sender)
    NSApp.delegate.concSortSelect.removeItemAtIndex(@sortOrderAryCtl.selectionIndex) if NSApp.delegate.concSortSelect.itemArray.length > @sortOrderAryCtl.selectionIndex
    @sortOrderAryCtl.remove(nil)
  end
  
  def restoreDefaultSortOrder(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to restore the default sort orders?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This cannot be undone.")
    alert.buttons[1].setKeyEquivalent("\e")
    userChoice = alert.runModal
    return if userChoice == -1
    
    userDefaultFilePath = NSBundle.mainBundle.pathForResource("UserDefaults",ofType:"plist")
    userDefaultValues = NSDictionary.dictionaryWithContentsOfFile(userDefaultFilePath)
    Defaults['sortOrder'] = userDefaultValues['sortOrder']
    NSApp.delegate.concSortSelect.removeAllItems
    Defaults['sortOrder'].each do |soVal|
      NSApp.delegate.concSortSelect.addItemWithTitle(soVal['sortOrder'])
    end
  end
  

  def selectAppForFile(sender)
    panel = NSOpenPanel.openPanel
  	panel.setTitle("Select an application for #{@fileTypesForApp[@currentSender]} files")
  	panel.setCanChooseDirectories(false)
  	panel.setCanChooseFiles(true)
  	panel.setAllowsMultipleSelection(false)
  	panel.setAllowedFileTypes([:app])
    panel.setDirectoryURL(NSURL.URLWithString("Applications"))
    panel.beginSheetModalForWindow(@selectAppForFilePanel,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        Defaults[@assignedAppTypes[sender.tag]] = File.basename(panel.filename,".*")
      end
    })
  end
  
  
  
  def selectDefaultFolder(sender)
    panel = NSOpenPanel.openPanel
  	panel.setTitle("Select a folder for #{@dataTypeForFolder[sender.tag]}")
  	panel.setCanChooseDirectories(true)
  	panel.setCanChooseFiles(false)
  	panel.setAllowsMultipleSelection(false)
    panel.setDirectoryURL(NSURL.URLWithString(NSHomeDirectory()))
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        Defaults[@defaultFolderTypes[sender.tag]] = panel.filename
      end
    })
  end
  
  
  
  
  
  def resetContextColors(sender)
    userDefaultFilePath = NSBundle.mainBundle.pathForResource("UserDefaults",ofType:"plist")
    userDefaultValues = NSDictionary.dictionaryWithContentsOfFile(userDefaultFilePath)
    Defaults['concColor1'] = userDefaultValues['concColor1']
    Defaults['concColor2'] = userDefaultValues['concColor2']
    Defaults['concColor3'] = userDefaultValues['concColor3']
    Defaults['concColor4'] = userDefaultValues['concColor4']
    @coloringTable.reloadData
  end

  def changeContextWordStyle(sender)
    @coloringTable.reloadData
  end
  
	
  def numberOfRowsInTableView(tableView)
		case tableView
		when @coloringTable
			2
    end
  end
  
  def tableView(table,willDisplayCell:cell,forTableColumn:col,row:row)
    case table
    when @coloringTable
      cell.setFont(NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize']))
	  end
  end

  
  def tableView(tableView,objectValueForTableColumn:col,row:row)
		case tableView
		when @coloringTable
      concLine = NSMutableAttributedString.alloc.initWithString("Key context1 context2 context3 context4",attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
		  if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
        concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [0,3])
		  end
      concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults['concContextColor1']).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [4,8])
      concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults['concContextColor2']).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [13,8])
      concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults['concContextColor3']).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [22,8])
      concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults['concContextColor4']).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [31,8])
      if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
        concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: [13,8])
      else
        concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [13,8])
      end
  		concLine
    end
  end
  
  def windowDidBecomeKey(notification)
    if notification.object == self.window
      @initialGroup[0] = Defaults['wcHandlerGroup']
      @initialGroup[1][0] = Defaults['lemmaGroupChoice']
      @initialGroup[1][1] = Defaults['kwgGroupChoice']
      @initialGroup[1][2] = Defaults['spVarGroupChoice']
      @initialScope = Defaults['scopeOfContextChoice']
      @initialChecks[0][0] = Defaults['wchStopWordCheck']
      @initialChecks[0][1] = Defaults['wchSkipCharCheck']
      @initialChecks[0][2] = Defaults['wchIncludeWordCheck']
      @initialChecks[0][3] = Defaults['wchMultiWordCheck']
      @initialChecks[1][0] = Defaults['lemmaCheck']
      @initialChecks[1][1] = Defaults['kwgCheck']
      @initialChecks[1][2] = Defaults['spVarCheck']
      @initialChecks[2] = Defaults['replaceCharCheck']
      @initialChecks[3][0] = Defaults['qouteIncludeCheck']
      @initialChecks[3][1] = Defaults['hyphenIncludeCheck'] 
      @initialChecks[3][2] = Defaults['othersIncludeCheck'] 
    end
  end
  
  def windowWillClose(notification)
    @sortOrderPanel.close
  end

  def windowDidResignKey(notification)    
    if notification.object == self.window
      listItems = ListItemProcesses.new
      listItems.stopWordPrepare if Defaults['wchStopWordCheck'] && (@initialChecks[0][0] != true || Defaults['wcHandlerGroup'] != @initialGroup[0] || NSApp.delegate.changeFlags[0][0] == 1)
      listItems.skipCharPrepare if Defaults['wchSkipCharCheck'] && (@initialChecks[0][1] != true || Defaults['wcHandlerGroup'] != @initialGroup[0] || NSApp.delegate.changeFlags[0][1] == 1)
      listItems.includeWordPrepare if Defaults['wchIncludeWordCheck'] && (@initialChecks[0][2] != true || Defaults['wcHandlerGroup'] != @initialGroup[0] || NSApp.delegate.changeFlags[0][2] == 1)
      listItems.multiWordPrepare if Defaults['wchMultiWordCheck'] && (@initialChecks[0][3] != true || Defaults['wcHandlerGroup'] != @initialGroup[0] || NSApp.delegate.changeFlags[0][3] == 1)
      listItems.eosWordPrepare if Defaults['scopeOfContextChoice'] == 2 && @initialScope != 2 && (Defaults['wcHandlerGroup'] != @initialGroup[0] || NSApp.delegate.changeFlags[0][4] == 1)

      listItems.lemmaPrepare if Defaults['lemmaCheck'] && (@initialChecks[1][0] != true || @initialGroup[1][0] != Defaults['lemmaGroupChoice'] || NSApp.delegate.changeFlags[1][0] == 1)
      listItems.kwgPrepare if Defaults['kwgCheck'] && (@initialChecks[1][1] != true || @initialGroup[1][1] != Defaults['kwgGroupChoice'] || NSApp.delegate.changeFlags[1][1] == 1)
      listItems.spvPrepare if Defaults['spVarCheck'] && (@initialChecks[1][2] != true || @initialGroup[1][2] != Defaults['spVarGroupChoice'] || NSApp.delegate.changeFlags[1][2] == 1)

      listItems.charReplacePrepare if Defaults['replaceCharCheck'] && (@initialChecks[2] != Defaults['replaceCharCheck'] || (NSApp.delegate.replaceCharsPanel && NSApp.delegate.replaceCharsPanel.changeFlag == 1))
      
      listItems.includeAsPartWordPrepare if (@initialChecks[3][0] != Defaults['qouteIncludeCheck']) || (@initialChecks[3][1] != Defaults['hyphenIncludeCheck']) || (@initialChecks[3][2] != Defaults['othersIncludeCheck'])
    end
  end
  
  
end