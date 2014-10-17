#
#  MyDocument.rb
#  CasualConc
#
#  Created by Yasu on 10/12/05.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class EditorWindowController < NSWindowController
  
  attr_accessor :textView, :encoding, :path, :appInfoObjCtl
  
  def windowNibName
    "EditorWindow"
  end
  
  def awakeFromNib
  end
  
  def setEditorText(item)
    @textView.setString(NSString.alloc.initWithContentsOfFile(item['path'],encoding:FileEncoding[item['encoding']],error:nil))
    self.window.setTitle(item['filename'])
    @encoding = item['encoding']
    @path = item['path']
  end
  
  def saveEditorDoc(sender)
    @textView.string.writeToFile(@path, atomically: true, encoding: FileEncoding[@encoding], error: nil)
    @appInfoObjCtl.content.removeObjectForKey('docEdited')
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
  
  def textDidChange(notification)
    if notification.object == @textView
      @appInfoObjCtl.content['docEdited'] = 1
    end
  end
end
