class MyTableView < NSTableView
  
  attr_accessor :oldText
  
  def textDidBeginEditing(notification)
    @oldText = notification.object.string.dup
  end
  
  def textDidEndEditing(notification)
    if !@oldText.nil?
      if notification.object.string == ""
        alert = NSAlert.alertWithMessageText("The text cell is empty.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"You cannot leave a text cell blank.")
                                            
        notification.object.insertText(@oldText)
        notification.object.resignFirstResponder
        alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
        return
      end
      if NSApp.delegate.wcHandlerWindow && notification.object.window == NSApp.delegate.wcHandlerWindow.window
        case self
        when NSApp.delegate.wcHandlerWindow.groupTable
          oldDir = "#{WCHFolderPath}/#{@oldText}"
          newDir = "#{WCHFolderPath}/#{notification.object.string}"
          NSFileManager.defaultManager.createDirectoryAtPath(newDir, withIntermediateDirectories: true, attributes: nil, error: nil)
          if NSFileManager.defaultManager.fileExistsAtPath(oldDir)
            NSFileManager.defaultManager.contentsOfDirectoryAtPath(oldDir, error: nil).each do |fn|
              NSFileManager.defaultManager.moveItemAtPath("#{oldDir}/#{fn}", toPath: "#{newDir}/#{fn}", error: nil)
            end
          end
          NSFileManager.defaultManager.removeItemAtPath(oldDir, error: nil)
          NSApp.delegate.currentGroups[0] = notification.object.string.dup
        else
          if NSApp.delegate.wcHandlerWindow.initialGroup == Defaults['wcHandlerGroup']
            case self
            when NSApp.delegate.wcHandlerWindow.stopWordTable
              NSApp.delegate.changeFlags[0][0] = 1 
            when NSApp.delegate.wcHandlerWindow.skipCharTable
              NSApp.delegate.changeFlags[0][1] = 1
            when NSApp.delegate.wcHandlerWindow.includeWordTable
              NSApp.delegate.changeFlags[0][2] = 1
            when NSApp.delegate.wcHandlerWindow.multiWordTable
              NSApp.delegate.changeFlags[0][3] = 1
            when NSApp.delegate.wcHandlerWindow.nonEOSWordTable
              NSApp.delegate.changeFlags[0][4] = 1
            end
          end
        end
      elsif NSApp.delegate.lemmaKWGSPVWindow && notification.object.window == NSApp.delegate.lemmaKWGSPVWindow.window
        tabIndex = NSApp.delegate.lemmaKWGSPVWindow.lkpTabView.indexOfTabViewItem(NSApp.delegate.lemmaKWGSPVWindow.lkpTabView.selectedTabViewItem)
        case self
        when NSApp.delegate.lemmaKWGSPVWindow.lemmaGroupTable, NSApp.delegate.lemmaKWGSPVWindow.keywordGroupTable, NSApp.delegate.lemmaKWGSPVWindow.spellVarGroupTable
          groupType = ['lemma','kwg','spv']
          oldDir = "#{LKSListFolderPath}/#{groupType[tabIndex]}/#{@oldText}"
          newDir = "#{LKSListFolderPath}/#{groupType[tabIndex]}/#{notification.object.string}"
          NSFileManager.defaultManager.createDirectoryAtPath(newDir, withIntermediateDirectories: true, attributes: nil, error: nil)
          if NSFileManager.defaultManager.fileExistsAtPath(oldDir)
            NSFileManager.defaultManager.contentsOfDirectoryAtPath(oldDir, error: nil).each do |fn|
              NSFileManager.defaultManager.moveItemAtPath("#{oldDir}/#{fn}", toPath: "#{newDir}/#{fn}", error: nil)
            end
          end  
          NSFileManager.defaultManager.removeItemAtPath(oldDir, error: nil)
          NSApp.delegate.currentGroups[1] = notification.object.string.dup
        else
          case self
          when NSApp.delegate.lemmaKWGSPVWindow.lemmaTable
            NSApp.delegate.changeFlags[1][0] = 1 if NSApp.delegate.lemmaKWGSPVWindow.initialGroup[0] == Defaults['lemmaGroupChoice']
          when NSApp.delegate.lemmaKWGSPVWindow.kwgTable
            NSApp.delegate.changeFlags[1][1] = 1 if NSApp.delegate.lemmaKWGSPVWindow.initialGroup[1] == Defaults['kwgGroupChoice']
          when NSApp.delegate.lemmaKWGSPVWindow.spellVarTable
            NSApp.delegate.changeFlags[1][2] = 1 if NSApp.delegate.lemmaKWGSPVWindow.initialGroup[2] == Defaults['spVarGroupChoice']
          end
          case self.editedColumn
          when 0
            oldKey = @oldText
            newKey = notification.object.string.dup
            oldWords = newWords = self.tableColumns[0].infoForBinding("value")["NSObservedObject"].arrangedObjects[self.selectedRow]['words']
          when 1
            oldKey = newKey = self.tableColumns[0].infoForBinding("value")["NSObservedObject"].arrangedObjects[self.selectedRow]['key']
            oldWords = @oldText
            newWords = notification.object.string.dup
          end
          NSApp.delegate.lemmaKWGSPVWindow.keywordHashes[tabIndex][0].delete(oldKey)
          case tabIndex
          when 0,2
            oldWords.split(",").each do |word|
              NSApp.delegate.lemmaKWGSPVWindow.keywordHashes[tabIndex][1].delete(word)
            end
            NSApp.delegate.lemmaKWGSPVWindow.keywordHashes[tabIndex][0][newKey] = ([newKey] + newWords.split(",")).map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
            newWords.split(",").each do |word|
              NSApp.delegate.lemmaKWGSPVWindow.keywordHashes[tabIndex][1][word] = newKey
            end
          when 1
            NSApp.delegate.lemmaKWGSPVWindow.keywordHashes[tabIndex][0][newKey] = newWords.split(",").map{|x| x.strip}.sort_by{|x| -x.length}.join("|")
          end
        end      
      end
    end
  end
end


class MyNonEdTableView < NSTableView
  def menuForEvent(event)
    row = self.rowAtPoint(self.convertPoint(event.locationInWindow,fromView:nil))
    if !row.nil? && !self.isRowSelected(row)
      self.selectRowIndexes(NSIndexSet.indexSetWithIndex(row),byExtendingSelection:false)
    end
    return super
  end
end


class MyNonEdTableHeaderView < NSTableHeaderView
  def menuForEvent(event)
    col = self.columnAtPoint(self.convertPoint(event.locationInWindow,fromView:nil))
    if !col.nil? && !self.tableView.isColumnSelected(col)
      self.tableView.selectColumnIndexes(NSIndexSet.indexSetWithIndex(col),byExtendingSelection:false)
    end
    return super
  end
end