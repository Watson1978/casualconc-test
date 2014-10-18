#
#  LemmaKYGSPVarListWindowController.rb
#  CasualConc
#
#  Created by Yasu on 10/11/24.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class LemmaKYGSPVarListController < NSWindowController
  extend IB
  
  outlet :lkpTabView
  outlet :lkpGroupTabView
  outlet :appInfoObjCtl
  outlet :encodingView
  outlet :splitView
  outlet :importChoiceView
  outlet :progressCircle
  outlet :removeGroupBtn
  outlet :removeEntryBtn
  outlet :exportEntryListBtn
  outlet :importEntryListBtn
  outlet :rebuldBtn
  outlet :delDupBtn
  outlet :keywordText
  outlet :wordsText
  outlet :lemmaAryCtl
  outlet :keywordAryCtl
  outlet :spellVarAryCtl
  outlet :lemmaGroupAryCtl
  outlet :keywordGroupAryCtl
  outlet :spellVarGroupAryCtl
  outlet :lemmaTable
  outlet :kwgTable
  outlet :spellVarTable
  outlet :lemmaGroupTable
  outlet :keywordGroupTable
  outlet :spellVarGroupTable
  outlet :keywordHashes
  outlet :initialGroup

	def windowNibName
    "LemmaKYGSPVarList"
  end
  
  def awakeFromNib
  #def windowDidLoad
    @aryCtl = [@lemmaAryCtl,@keywordAryCtl,@spellVarAryCtl]
    @groupAryCtl = [@lemmaGroupAryCtl,@keywordGroupAryCtl,@spellVarGroupAryCtl]
    @groupTable = [@lemmaGroupTable,@keywordGroupTable,@spellVarGroupTable]
    @groupType = ['lemma','kwg','spv']
    @groupUDName = ['lemmaGroupChoice','kwgGroupChoice','spVarGroupChoice']
    self.changeTabView(nil)
    @keywordHashes = [[{},{}],[{},{}],[{},{}]]
    @appInfoObjCtl.content['encoding'] = 0
    @appInfoObjCtl.content['keyDivider'] = 0
    @appInfoObjCtl.content['itemDivider'] = 0
    @progressCircle.setDisplayedWhenStopped(false)
    @progressCircle.setUsesThreadedAnimation(true)
    NSApp.delegate.currentGroups[1] = NSApp.delegate.currentGroups[1]
    @initialGroup = Array.new(3)
    @initialCheck = Array.new(3)
  end
  

  def changeTabView(sender)
    @currentTab = sender.nil? ? 0 : sender.tag
    self.updateWordList('tab') if @groupAryCtl[@currentTab].selectedObjects.length > 0
    @lkpTabView.selectTabViewItemAtIndex(@currentTab)
    @lkpGroupTabView.selectTabViewItemAtIndex(@currentTab)
    @removeGroupBtn.unbind("enabled")
    @removeGroupBtn.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    @removeEntryBtn.unbind("enabled")
    @removeEntryBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    #@removeEntryBtn.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    @exportEntryListBtn.unbind("enabled")
    @exportEntryListBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "arrangedObjects", options: {NSValueTransformerNameBindingOption => 'ArrayExistTransformer'})
    #@exportEntryListBtn.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    @importEntryListBtn.unbind("enabled")
    @importEntryListBtn.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)

    @rebuldBtn.unbind("enabled")
    @rebuldBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "arrangedObjects", options: {NSValueTransformerNameBindingOption => 'ArrayExistTransformer'})
    @delDupBtn.unbind("enabled")
    @delDupBtn.bind("enabled", toObject: @aryCtl[@currentTab], withKeyPath: "arrangedObjects", options: {NSValueTransformerNameBindingOption => 'ArrayExistTransformer'})
    #@delDupBtn.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)

    @keywordText.unbind("enabled")
    @keywordText.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)
    @wordsText.unbind("enabled")
    @wordsText.bind("enabled", toObject: @groupAryCtl[@currentTab], withKeyPath: "canRemove", options: nil)

    NSApp.delegate.currentGroups[1] = @groupAryCtl[@currentTab].selectedObjects.length > 0 ? @groupAryCtl[@currentTab].selectedObjects[0]['group'] : nil
  end

  
  def addGroup(sender)
    newGroupName = @appInfoObjCtl.content['groupText'].strip
    if @groupAryCtl[@currentTab].arrangedObjects.select{|x| x['group'].downcase == newGroupName.downcase}.length > 0
      alert = NSAlert.alertWithMessageText("This group label is already used.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please use another label.")
      
      alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
        alert.window.orderOut(nil)
        if returnCode == 1
          @appInfoObjCtl.content.removeObjectForKey('groupText')
        end
      })
    else
      @groupAryCtl[@currentTab].addObject({'group' => newGroupName})
      @appInfoObjCtl.content.removeObjectForKey('groupText')
      fileManager = NSFileManager.defaultManager
      fileManager.createDirectoryAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{newGroupName}", withIntermediateDirectories: true, attributes: nil, error: nil)
    end
    
  end
  


  def removeGroup(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete the selected group?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This process cannot be undone.")
    alert.buttons[1].setKeyEquivalent("\e")                                    
    alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      alert.window.orderOut(nil)
      if returnCode == 1
        groupName = @groupAryCtl[@currentTab].arrangedObjects[@groupAryCtl[@currentTab].selectionIndex]['group']
        NSFileManager.defaultManager.removeItemAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{groupName}", error: nil)
        @groupAryCtl[@currentTab].removeObjectAtArrangedObjectIndex(@groupAryCtl[@currentTab].selectionIndex)
        Defaults[@groupUDName[@currentTab]] = 0
      end
    })
  end
  
  
  
  
  def addNewEntry(sender)
    if @aryCtl[@currentTab].arrangedObjects.select{|x| x['key'].downcase == @appInfoObjCtl.content['keyword'].downcase}.length > 0
      alert = NSAlert.alertWithMessageText("This word/keyword is already on the list.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"You cannot add the same word/keyword.")
      
      alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
    else
      @aryCtl[@currentTab].addObject({'key' => @appInfoObjCtl.content['keyword'],'words' => @appInfoObjCtl.content['words']})
      case @currentTab
      when 0,2
        @keywordHashes[@currentTab][0][@appInfoObjCtl.content['keyword']] = ([@appInfoObjCtl.content['keyword']] + (@appInfoObjCtl.content['words']).split(",")).map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
        @appInfoObjCtl.content['words'].split(",").map{|x| x.strip}.each do |word|
          @keywordHashes[@currentTab][1][word] = @appInfoObjCtl.content['keyword']
        end
      when 1
        @keywordHashes[@currentTab][0][@appInfoObjCtl.content['keyword']] = @appInfoObjCtl.content['words'].split(",").map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
      end
            
      @appInfoObjCtl.content.removeObjectForKey('keyword')
      @appInfoObjCtl.content.removeObjectForKey('words')
      NSApp.delegate.changeFlags[1][@currentTab] = 1 if @initialGroup[@currentTab] == Defaults[@groupUDName[@currentTab]]
      
    end
  end

  
  def removeEntry(sender)
    @aryCtl[@currentTab].selectedObjects.each do |item|
      @keywordHashes[@currentTab][0].delete(item['key'])
      if not @currentTab == 1
        item['words'].split(",").each do |word|
          @keywordHashes[@currentTab][1].delete(word)
        end
      end
    end
    @aryCtl[@currentTab].removeObjectsAtArrangedObjectIndexes(@aryCtl[@currentTab].selectionIndexes)
    NSApp.delegate.changeFlags[1][@currentTab] = 1 if @initialGroup[@currentTab] == Defaults[@groupUDName[@currentTab]]    
  end
  

  
  
  def importList(sender)
    panel = NSOpenPanel.openPanel
  	panel.setTitle("Select a list file.")
  	panel.setCanChooseDirectories(false)
  	panel.setCanChooseFiles(true)
  	panel.setAllowsMultipleSelection(false)
  	panel.setAccessoryView(@importChoiceView)
    panel.setAllowedFileTypes([:txt])
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |result|
      panel.close
      if result == 1
        if (@appInfoObjCtl.content['keyDivider'] == 3 && @appInfoObjCtl.content['keyDividerText'].nil?) || (@appInfoObjCtl.content['itemDivider'] == 3 && @appInfoObjCtl.content['itemDividerText'].nil?)
          alert = NSAlert.alertWithMessageText("Divider(s) is not specified.",
                                               defaultButton:"OK",
                                               alternateButton:nil,
                                               otherButton:nil,
                                               informativeTextWithFormat:"You need to specify a dividier if you choose 'Other'.")

          alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
        else
          @progressCircle.startAnimation(nil)
          keyDivider = case @appInfoObjCtl.content['keyDivider']
          when 0
            "->"
          when 1
            "\t"
          when 2
            " "
          when 3
            @appInfoObjCtl.content['keyDividerText']
          end
          itemDivider = case @appInfoObjCtl.content['itemDivider']
          when 0
            ","
          when 1
            " "
          when 2
            @appInfoObjCtl.content['itemDividerText']
          end
          skipLineCharReg = @appInfoObjCtl.content['skipLineChar'].to_s
          wordList = NSString.alloc.initWithContentsOfFile(panel.filename,encoding:TextEncoding[@appInfoObjCtl.content['encoding']],error:nil)        
          wordListAry = []
          wordList.split(/(?:\r*\n)+/).each do |line|
            next if line.strip == "" || line[0] == skipLineCharReg
            items = line.split(keyDivider)
            next if items[1].nil?
            key = items[0].strip
            words = items[1].strip.split(itemDivider).map{|x| x.strip}
            wordListAry << {'key' => key,'words' => words.join(",")}
            case @currentTab
            when 0,2
              @keywordHashes[@currentTab][0][key] = (words + [key]).map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
              words.each do |word|
                @keywordHashes[@currentTab][1][word] = key
              end
            when 1
              @keywordHashes[@currentTab][0][key] = words.map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
            end
          end
          origLength = wordListAry.length
          wordListAry.delete_if{|x| @aryCtl[@currentTab].arrangedObjects.select{|y| y['key'].downcase == x['key'].downcase}.length > 0}
          @aryCtl[@currentTab].addObjects(wordListAry) if wordListAry.length > 0
          @progressCircle.stopAnimation(nil)
          NSApp.delegate.changeFlags[1][@currentTab] = 1 if @initialGroup[@currentTab] == Defaults[@groupUDName[@currentTab]]

          if origLength > wordListAry.length
            alert = NSAlert.alertWithMessageText(NSString.stringWithFormat("%1$@ of %2$@ were imported.",wordListAry.length,origLength),
                                                 defaultButton:"OK",
                                                 alternateButton:nil,
                                                 otherButton:nil,
                                                 informativeTextWithFormat:"Only the words/keywords that are not on the list were added.")
      
            alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
          end
        end
      end
    })
  end
  
  
  
  def exportList(sender)
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
  
  
  
  def rebuildData(sender)
    @keywordHashes[@currentTab][0].removeAllObjects
    @keywordHashes[@currentTab][1].removeAllObjects
    @aryCtl[@currentTab].arrangedObjects.each do |item|
      @keywordHashes[@currentTab][0][item['key']] = ([item['key']] + item['words'].split(",")).sort_by{|x| -x.length}.join("|")
      item['words'].split(",").each do |word|
        @keywordHashes[@currentTab][1][word] = item['key']
      end      
    end
    if @keywordHashes[@currentTab][0].length == @aryCtl[@currentTab].arrangedObjects.length
      msg = "Data was successfully rebult."
    else
      msg = "Some entries were not processed."
    end
    alert = NSAlert.alertWithMessageText(msg,
                                         defaultButton:"OK",
                                         alternateButton:nil,
                                         otherButton:nil,
                                         informativeTextWithFormat:"")

    alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
  end



  def updateWordList(sender)
    if @aryCtl[@currentTab].arrangedObjects.length > 0
      @aryCtl[@currentTab].arrangedObjects.writeToFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/mainlist", atomically: true)
      @keywordHashes[@currentTab][0].writeToFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/eachitemlist", atomically: true)
      @keywordHashes[@currentTab][1].writeToFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/keylist", atomically: true) if @currentTab != 1
    elsif @aryCtl[@currentTab].arrangedObjects.length == 0 && NSFileManager.defaultManager.fileExistsAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/mainlist")
      NSFileManager.defaultManager.removeItemAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/mainlist", error: nil)
      NSFileManager.defaultManager.removeItemAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/eachitemlist", error: nil)
      NSFileManager.defaultManager.removeItemAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{NSApp.delegate.currentGroups[1]}/keylist", error: nil) if @currentTab != 1
    end
  end
  
  
  def tableViewSelectionDidChange(notification)
    case notification.object
    when @groupTable[@currentTab]
      if NSApp.delegate.currentGroups[1].nil? 
        @aryCtl[@currentTab].addObjects(NSArray.arrayWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/mainlist"))
        @keywordHashes[@currentTab][0].addEntriesFromDictionary(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/eachitemlist"))
        @keywordHashes[@currentTab][1].addEntriesFromDictionary(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/keylist")) if @currentTab != 1
        NSApp.delegate.currentGroups[1] = @groupAryCtl[@currentTab].selectedObjects[0]['group']        
      else
        if @groupAryCtl[@currentTab].arrangedObjects.select{|x| x['group'] == NSApp.delegate.currentGroups[1]}.length > 0
          self.updateWordList('table')
        end
        if @groupAryCtl[@currentTab].selectedObjects.length > 0
          @aryCtl[@currentTab].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@aryCtl[@currentTab].arrangedObjects.length]))
          @keywordHashes[@currentTab][0].removeAllObjects
          @keywordHashes[@currentTab][1].removeAllObjects
          @aryCtl[@currentTab].addObjects(NSArray.arrayWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/mainlist")) if NSFileManager.defaultManager.fileExistsAtPath("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/mainlist")
          @keywordHashes[@currentTab][0].addEntriesFromDictionary(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/eachitemlist"))
          @keywordHashes[@currentTab][1].addEntriesFromDictionary(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/#{@groupType[@currentTab]}/#{@groupAryCtl[@currentTab].selectedObjects[0]['group']}/keylist")) if @currentTab != 1
          NSApp.delegate.currentGroups[1] = @groupAryCtl[@currentTab].selectedObjects[0]['group']        
        else
          @aryCtl[@currentTab].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@aryCtl[@currentTab].arrangedObjects.length]))
          @keywordHashes[@currentTab][0].removeAllObjects
          @keywordHashes[@currentTab][1].removeAllObjects
          NSApp.delegate.currentGroups[1] = nil
        end
      end
    end  
  end
  
  
  
  def windowDidBecomeKey(notification)
    3.times do |i|
      @initialGroup[i] = Defaults[@groupUDName[i]]
    end
    @initialCheck[0] = Defaults['lemmaCheck']
    @initialCheck[1] = Defaults['kwgCheck']
    @initialCheck[2] = Defaults['spVarCheck']
  end
  
  def windowDidResignKey(notification)
 
    if notification.object == self.window
      self.updateWordList('window') if @groupAryCtl[@currentTab].selectedObjects.length > 0
      listItems = ListItemProcesses.new
      if Defaults['lemmaGroups'].length > 0 && Defaults['lemmaCheck'] && (@initialGroup[0] != Defaults[@groupUDName[0]] || @initialCheck[0] != true || NSApp.delegate.changeFlags[1][0] == 1)
        listItems.lemmaPrepare
        NSApp.delegate.changeFlags[1][0] = 0
      end
      if Defaults['kwgGroups'].length > 0 && Defaults['kwgCheck'] && (@initialGroup[1] != Defaults[@groupUDName[1]] || @initialCheck[1] != true || NSApp.delegate.changeFlags[1][1] == 1)
        listItems.kwgPrepare
        NSApp.delegate.changeFlags[1][1] = 0
      end
      if Defaults['spVarGroups'].length > 0 && Defaults['spVarCheck'] && (@initialGroup[2] != Defaults[@groupUDName[2]] || @initialCheck[2] != true || NSApp.delegate.changeFlags[1][2] == 1)
        listItems.spvPrepare
        NSApp.delegate.changeFlags[1][2] = 0
      end
      NSApp.delegate.changeFlags[0] = [0,0,0]
    end
  end
  
  
  def splitView(splitView, constrainSplitPosition: constrainSplitPosition, ofSubviewAt: subviewAt)
    249
  end  
  
  def windowDidResize(notification)
    if notification.object == self.window
      @splitView.setPosition(249, ofDividerAtIndex: 0)
    end
  end
  
end
