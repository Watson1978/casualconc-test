#
#  WordCharHandlingWindowController.rb
#  CasualConc
#
#  Created by Yasu on 10/11/21.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class WordCharHandlingController < NSWindowController
  extend IB

  outlet :wchTabView
  outlet :removeWordBtn
  outlet :exportWordListBtn
  outlet :appInfoObjCtl
  outlet :encodingView
  outlet :importListFromGroupPanel
  outlet :splitView
  outlet :groupTable
  outlet :stopWordTable
  outlet :skipCharTable
  outlet :includeWordTable
  outlet :multiWordTable
  outlet :nonEOSWordTable
  outlet :groupAryCtl
  outlet :stopWordAryCtl
  outlet :skipCharAryCtl
  outlet :includeWordAryCtl
  outlet :multiWordAryCtl
  outlet :nonEOSWordAryCtl
  outlet :initialGroup
  
  def windowNibName
    "WordCharHandling"
  end
  
  def awakeFromNib
  #def windowDidLoad
    @table = [@stopWordTable,@skipCharTable,@includeWordTable,@multiWordTable,@nonEOSWordTable]
    @aryCtl = [@stopWordAryCtl,@skipCharAryCtl,@includeWordAryCtl,@multiWordAryCtl,@nonEOSWordAryCtl]
    @tabLabels = ["stop","skip","include","multiword","notEnd"]
    @removeWordBtn.bind("enabled", toObject: @aryCtl[0], withKeyPath: "canRemove", options: nil)
    @exportWordListBtn.bind("enabled", toObject: @aryCtl[0], withKeyPath: "arrangedObjects", options: {NSValueTransformerNameBindingOption => 'ArrayExistTransformer'})
    @currentTab = @wchTabView.indexOfTabViewItem(@wchTabView.selectedTabViewItem)
    @appInfoObjCtl.content['encoding'] = 0
    @appInfoObjCtl.content['wordImportSource'] = 0
    @appInfoObjCtl.content['importGroup'] = 0
    @splitView.setPosition(289, ofDividerAtIndex: 0)
  end
  

  
  def addGroup(sender)
    newGroupName = @appInfoObjCtl.content['groupText'].strip
    if @groupAryCtl.arrangedObjects.select{|x| x['group'].downcase == newGroupName.downcase}.length > 0
      alert = NSAlert.alertWithMessageText("This group label is already used.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please use another label.")
      
      alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
        @appInfoObjCtl.content.removeObjectForKey('groupText') if returnCode == 1
      })
    else
      @groupAryCtl.addObject({'group' => newGroupName})
      @appInfoObjCtl.content.removeObjectForKey('groupText')
      fileManager = NSFileManager.defaultManager
      fileManager.createDirectoryAtPath("#{WCHFolderPath}/#{newGroupName}", withIntermediateDirectories: true, attributes: nil, error: nil)
    end
    
  end
    
  
  
  def removeGroup(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete the selected group?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This process cannot be undone.")
                                        
    alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      if returnCode == 1
        groupName = @groupAryCtl.arrangedObjects[@groupAryCtl.selectionIndex]['group']
        NSFileManager.defaultManager.removeItemAtPath("#{WCHFolderPath}/#{groupName}", error: nil)
        @groupAryCtl.removeObjectAtArrangedObjectIndex(@groupAryCtl.selectionIndex)
        Defaults['wcHandlerGroup'] = 0
      end
    })
  end
    

  def addNewWord(sender)
    if @aryCtl[@currentTab].arrangedObjects.select{|x| x['word'].downcase == @appInfoObjCtl.content['wcText'].downcase}.length > 0
      alert = NSAlert.alertWithMessageText("This word/character is already on the list.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"You cannot add the same word/character.")
      
      alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })      
    else
      @aryCtl[@currentTab].addObject({'word' => @appInfoObjCtl.content['wcText']})
      @appInfoObjCtl.content.removeObjectForKey('wcText')
      NSApp.delegate.changeFlags[0][@currentTab] = 1 if Defaults['wcHandlerGroup'] == @initialGroup
    end
  end


  
  def removeWord(sender)
    @aryCtl[@currentTab].removeObjectsAtArrangedObjectIndexes(@aryCtl[@currentTab].selectionIndexes)
    NSApp.delegate.changeFlags[0][@currentTab] = 1 if Defaults['wcHandlerGroup'] == @initialGroup
  end
  

  def importWordList(sender)
    if @appInfoObjCtl.content['wordImportSource'] == 0
      panel = NSOpenPanel.openPanel
    	panel.setTitle("Select a list file.")
    	panel.setCanChooseDirectories(false)
    	panel.setCanChooseFiles(true)
    	panel.setAllowsMultipleSelection(false)
    	panel.setAccessoryView(@encodingView)
      panel.setAllowedFileTypes([:txt])
      panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |result|
        panel.close
        if result == 1
          wordList = NSString.alloc.initWithContentsOfFile(panel.filename,encoding:TextEncoding[@appInfoObjCtl.content['encoding']],error:nil)        
          wordListAry = wordList.split(/(?:\r*\n)+/).delete_if{|x| x.strip == ""}.map{|x| {'word' => x.strip}}
          origLength = wordListAry.length
          wordListAry.delete_if{|x| @aryCtl[@currentTab].arrangedObjects.select{|y| y['word'].downcase == x['word'].downcase}.length > 0}
          @aryCtl[@currentTab].addObjects(wordListAry) if wordListAry.length > 0
          NSApp.delegate.changeFlags[0][@currentTab] = 1 if Defaults['wcHandlerGroup'] == @initialGroup

          if origLength > wordListAry.length
            alert = NSAlert.alertWithMessageText(NSString.stringWithFormat("%1$@ of %2$@ were imported.",wordListAry.length,origLength),
                                                 defaultButton:"OK",
                                                 alternateButton:nil,
                                                 otherButton:nil,
                                                 informativeTextWithFormat:"Only the words/characters that are not on the list were added.")
      
            alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })      
          end
        end
      })
    else
      self.window.beginSheet(@importListFromGroupPanel,completionHandler:Proc.new { |returnCode| })    
    end
	  
  end
  
  def sheetDidEnd(sheet, returnCode: returnCode, contextInfo: info)
    sheet.close
  end
  
  def importWordListFromGroup(sender)
    if sender.tag == 0
      if @appInfoObjCtl.content['importGroup'] == @groupAryCtl.selectionIndex
        alert = NSAlert.alertWithMessageText("Please select other group.",
                                             defaultButton:"OK",
                                             alternateButton:nil,
                                             otherButton:nil,
                                             informativeTextWithFormat:"You cannot import from the same group.")
      
        alert.beginSheetModalForWindow(@importListFromGroupPanel,completionHandler:Proc.new { |returnCode| })      
        return
      else
        self.window.endSheet(@importListFromGroupPanel)
        if NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{@groupAryCtl.arrangedObjects[@appInfoObjCtl.content['importGroup']]['group']}/#{@tabLabels[@currentTab]}")
          wordListAry = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{@groupAryCtl.arrangedObjects[@appInfoObjCtl.content['importGroup']]['group']}/#{@tabLabels[@currentTab]}")
          origLength = wordListAry.length
          wordListAry.delete_if{|x| @aryCtl[@currentTab].arrangedObjects.select{|y| y['word'].downcase == x['word'].downcase}.length > 0}
          @aryCtl[@currentTab].addObjects(importAry)
          NSApp.delegate.changeFlags[0][@currentTab] = 1 if Defaults['wcHandlerGroup'] != @initialGroup
          if wordListAry.length < origLength
            alert = NSAlert.alertWithMessageText(NSString.stringWithFormat("%1$@ of %2$@ were imported.",wordListAry.length,origLength),
                                                 defaultButton:"OK",
                                                 alternateButton:nil,
                                                 otherButton:nil,
                                                 informativeTextWithFormat:"Only the words/characters that are not on the list were added.")

            alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })      
          end
        
        else
          alert = NSAlert.alertWithMessageText(NSString.stringWithFormat("The source list you selected is empty."),
                                               defaultButton:"OK",
                                               alternateButton:nil,
                                               otherButton:nil,
                                               informativeTextWithFormat:"Please select a list that has words/characters.")

          alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })      
          return
        end
      end
    else
      self.window.endSheet(@importListFromGroupPanel)
    end
  end
  
  
  
  def exportWordList(sender)
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the file")
    panel.setCanSelectHiddenExtension(true)
    panel.setAccessoryView(@encodingView)
    panel.setAllowedFileTypes([:txt])
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |result|
      panel.close
      if returnCode == 1
        wordAry = @aryCtl[@currentTab].arrangedObjects
        wordAry.map{|x| x['word']}.join("\n").writeToFile(panel.filename, atomically: true, encoding: TextEncoding[@appInfoObjCtl.content['encoding']], error: nil)
      end
    })
  end
  
  

  def changeTabView(sender)
    self.updateWordList('tab') if @groupAryCtl.selectedObjects.length > 0
    @currentTab = sender.nil? ? 0 : sender.tag
    @wchTabView.selectTabViewItemAtIndex(@currentTab)
    @removeWordBtn.unbind("enabled")
    @removeWordBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    @exportWordListBtn.unbind("enabled")
    @exportWordListBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "arrangedObjects", options: {NSValueTransformerNameBindingOption => 'ArrayExistTransformer'})
  end

  

  def tabView(tabView, didSelectTabViewItem: item)
    #self.updateWordList('tab') if @groupAryCtl.selectedObjects.length > 0
    #@currentTab = @wchTabView.indexOfTabViewItem(@wchTabView.selectedTabViewItem)
  end


  
  def updateWordList(sender)
    if @aryCtl[@currentTab].arrangedObjects.length > 0 #|| NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}")
      @aryCtl[@currentTab].arrangedObjects.writeToFile("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}", atomically: true)
      if @currentTab == 2
        "#{@aryCtl[@currentTab].arrangedObjects.map{|x| Regexp.escape(x['word'])}.select{|x| x.match(/\W$/)}.join("|")}\n#{@aryCtl[@currentTab].arrangedObjects.map{|x| Regexp.escape(x['word'])}.select{|x| x.match(/\w$/)}.join("|")}".writeToFile("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}Text", atomically: true, encoding: TextEncoding[0], error: nil)
      elsif @currentTab == 1
        @aryCtl[@currentTab].arrangedObjects.map{|x| Regexp.escape(x['word'])}.sort_by{|x| -x.length}.join("").writeToFile("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}Text", atomically: true, encoding: TextEncoding[0], error: nil)
      else
        @aryCtl[@currentTab].arrangedObjects.map{|x| Regexp.escape(x['word'])}.sort_by{|x| -x.length}.join("|").writeToFile("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}Text", atomically: true, encoding: TextEncoding[0], error: nil)
      end
    elsif @aryCtl[@currentTab].arrangedObjects.length == 0 && NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}")
      NSFileManager.defaultManager.removeItemAtPath("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}", error: nil)
      NSFileManager.defaultManager.removeItemAtPath("#{WCHFolderPath}/#{NSApp.delegate.currentGroups[0]}/#{@tabLabels[@currentTab]}Text", error: nil)
    end
  end
  
  
  def tableViewSelectionDidChange(notification)
    case notification.object
    when @groupTable
      if NSApp.delegate.currentGroups[0].nil?
        @aryCtl.each_with_index do |aryCtl,idx|
          aryCtl.addObjects(NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{@groupAryCtl.selectedObjects[0]['group']}/#{@tabLabels[idx]}"))          
        end
        NSApp.delegate.currentGroups[0] = @groupAryCtl.selectedObjects[0]['group']        
      else
        if @groupAryCtl.arrangedObjects.select{|x| x['group'] == NSApp.delegate.currentGroups[0]}.length > 0
          self.updateWordList('table')
        end
        if @groupAryCtl.selectedObjects.length > 0
          @aryCtl.each_with_index do |aryCtl,idx|
            aryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,aryCtl.arrangedObjects.length]))
            aryCtl.addObjects(NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{@groupAryCtl.selectedObjects[0]['group']}/#{@tabLabels[idx]}")) if NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{@groupAryCtl.selectedObjects[0]['group']}/#{@tabLabels[idx]}")
          end
          NSApp.delegate.currentGroups[0] = @groupAryCtl.selectedObjects[0]['group']        
        else
          @aryCtl.each do |aryCtl|
            aryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,aryCtl.arrangedObjects.length]))
          end
          NSApp.delegate.currentGroups[0] = nil
        end
      end
    end  
  end


  def numberOfRowsInTableView(tableView)
    case tableView
    when @stopWordTable
      @stopWordAryCtl.arrangedObjects.length      
    when @skipCharTable
      @skipCharAryCtl.arrangedObjects.length
    when @includeWordTable
      @includeWordAryCtl.arrangedObjects.length
    when @multiWordTable
      @multiWordAryCtl.arrangedObjects.length
    when @nonEOSWordTable
      @nonEOSWordAryCtl.arrangedObjects.length
    end
  end


  def tableView(tableView,objectValueForTableColumn:col,row:row)
    case col
    when tableView.tableColumnWithIdentifier('id')
      row + 1
    end
  end

  def splitView(splitView, constrainSplitPosition: constrainSplitPosition, ofSubviewAt: subviewAt)
    289
  end  
  
  def windowDidResize(notification)
    if notification.object == self.window
      @splitView.setPosition(289, ofDividerAtIndex: 0)
    end
    @stopWordInitCheck = Defaults['wchStopWordCheck']
    @skipCharInitCheck = Defaults['wchSkipCharCheck']
    @includeWordInitInitCheck = Defaults['wchIncludeWordCheck']
    @multiwordInitCheck = Defaults['wchMultiWordCheck']    
  end
  
  def windowDidBecomeKey(notification)
    if notification.object == self.window
      @initialGroup = Defaults['wcHandlerGroup']
    end
  end
  
  #def windowWillClose(notification)
  #  if notification.object == self.window
  #    self.updateWordList('window') if @groupAryCtl.selectedObjects.length > 0
  #  end
  #end

  def windowDidResignKey(notification)
    if notification.object == self.window
      self.updateWordList('window') if @groupAryCtl.selectedObjects.length > 0
      #if Defaults['wcHandlerGroup'] != @initialGroup
        listItems = ListItemProcesses.new
        if Defaults['wchStopWordCheck'] && (@stopWordInitCheck != true || NSApp.delegate.changeFlags[0][0] == 1)
          listItems.stopWordPrepare 
          NSApp.delegate.changeFlags[0][0] = 0
        end
        if Defaults['wchSkipCharCheck'] && (@skipCharInitCheck != true || NSApp.delegate.changeFlags[0][1] == 1)
          listItems.skipCharPrepare
          NSApp.delegate.changeFlags[0][1] = 0
        end
        if Defaults['wchIncludeWordCheck'] && (@includeWordInitInitCheck != true || NSApp.delegate.changeFlags[0][2] == 1) 
          listItems.includeWordPrepare
          NSApp.delegate.changeFlags[0][2] = 0
        end
        if Defaults['wchMultiWordCheck'] && (@multiwordInitCheck != true || NSApp.delegate.changeFlags[0][3] == 1) 
          listItems.multiWordPrepare 
          NSApp.delegate.changeFlags[0][3] = 0
        end
        if Defaults['scopeOfContextChoice'] == 2 && NSApp.delegate.changeFlags[0][4] == 1 
          listItems.eosWordPrepare 
          NSApp.delegate.changeFlags[0][4] = 0 
        end
      #end
    end
  end
    
end
