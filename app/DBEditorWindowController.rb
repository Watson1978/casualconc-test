#
#  DBEditorWindowController.rb
#  CasualConc
#
#  Created by Yasu on 10/12/06.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class DBEditorWindowController < NSWindowController
  
  attr_accessor :path, :textView, :updateBtn, :encoding, :entryID, :dbPath
  
  def windowNibName
    "DBEditor"
  end
  
  def updateEntry(sender)
    text = @textView.string
    db = SQLite3::Database.new(@dbPath)
    db.transaction do
      db.execute("UPDATE conc_data SET text = ? WHERE id = #{@entryID}",text)
    end
    @updateBtn.setEnabled(false)
    
  end
  
  
  def textDidChange(notification)
    if notification.object == @textView
      @updateBtn.setEnabled(true)
    end
  end
  
  
  def displayText(item)
    db = SQLite3::Database.new(item['dbPath'])
  	db.transaction do
	    dbEntry = db.execute("SELECT text, path, encoding, id FROM conc_data WHERE id = ?",item['entryID'])[0]
      @path.setStringValue(dbEntry[1])      
      @textView.setString(dbEntry[0])
      @textView.setSelectedRange([0,0])
      @textView.scrollRangeToVisible([0,0])
      @encoding = dbEntry[2]
      @entryID = dbEntry[3]
      @updateBtn.setEnabled(false)
      @dbPath = item['dbPath']   
    end
  end
  
  
  
  def windowShouldClose(window)
    if window == self.window
      if @appInfoObjCtl.content['docEdited'] == 1
        alert = NSAlert.alertWithMessageText("Do you want to save the unsaved changes?",
                                            defaultButton:"Yes",
                                            alternateButton:"Cancel",
                                            otherButton:"No",
                                            informativeTextWithFormat:"All the unsaved changed will be gone.")
        alert.buttons[2].setKeyEquivalent("\e")
        userChoice = alert.runModal
        case userChoice
        when 0
          return false
        when 1
          self.saveEditorDoc(nil)
        end
      end
      NSApp.delegate.openedEditorDoc.delete_if{|x| x[0] == path.downcase}
    end
  end
  
end
