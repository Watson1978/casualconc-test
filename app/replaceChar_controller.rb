#
#  ReplaceCharWindowController.rb
#  CasualConc
#
#  Created by Yasu on 10/11/22.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.


class ReplaceCharController < NSWindowController
  extend IB

  outlet :appInfoObjCtl
  outlet :replaceCharAryCtl
  outlet :encodingView
  outlet :changeFlag

	def windowNibName
    "ReplaceChars"
  end
  
  def awakeFromNib
  #def windowDidLoad
    @appInfoObjCtl.content['encoding'] = 0
  end

  def addNewEntry(sender)
    @replaceCharAryCtl.addObject({'fromChar' => @appInfoObjCtl.content['fromChar'],'toChar' => @appInfoObjCtl.content['toChar']})
    @appInfoObjCtl.content.removeObjectForKey('fromChar')
    @appInfoObjCtl.content.removeObjectForKey('toChar')
    @changeFlag = 1
  end
	
  
	def clearTable(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to clear the table?",
                                         defaultButton:"Yes",
                                         alternateButton:nil,
                                         otherButton:"No",
                                         informativeTextWithFormat:"This process cannot be undone.")
    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      if returnCode == 1
        @replaceCharAryCtl.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@replaceCharAryCtl.arrangedObjects.length]))
        @changeFlag = 1
      end
    })
  end
	
	
	
	def removeEntries(sender)
	  @replaceCharAryCtl.removeObjectsAtArrangedObjectIndexes(@replaceCharAryCtl.selectionIndexes)
	  @changeFlag = 1
  end
	
	def importEntries(sender)
	  panel = NSOpenPanel.openPanel
  	panel.setTitle("Select a character replacement list file.")
  	panel.setCanChooseDirectories(false)
  	panel.setCanChooseFiles(true)
  	panel.setAllowsMultipleSelection(false)
  	panel.setAccessoryView(@encodingView)
    panel.setAllowedFileTypes([:txt])
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |result|
      panel.close
      if result == 1
        charList = NSString.alloc.initWithContentsOfFile(panel.filename,encoding:TextEncoding[@appInfoObjCtl.content['encoding']],error:nil)        
        charListAry = Array.new
        skipChars = Array.new
        charList.split(/(?:\r*\n)+/).each do |line|
          item = line.split("\t")
          if @replaceCharAryCtl.arrangedObjects.select{|x| x['fromChar'] == item[0]}.length > 0
            skipChars << item[0]
            next
          end
          charListAry << {'fromChar' => item[0],'toChar' => item[1],'check' => false}
        end
        @replaceCharAryCtl.addObjects(charListAry)
        @changeFlag = 1
      
        if skipChars.length > 0
          alert = NSAlert.alertWithMessageText("At least one character was not imported.",
                                              defaultButton:"OK",
                                              alternateButton:nil,
                                              otherButton:nil,
                                              informativeTextWithFormat:"Only the characters that are not on the list were added.")

          alert.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| })
        end
      end
    })

  end
  
  
  
  
  def exportEntries(sender)
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the file")
    panel.setCanSelectHiddenExtension(true)
    panel.setAccessoryView(@encodingView)
    panel.setAllowedFileTypes([:txt])
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |result|
      panel.close
      if returnCode == 1
        exportTextAry = Array.new
        charAry = @replaceCharAryCtl.arrangedObjects
        charAry.map{|x| "#{x['fromChar']}\t#{x['toChar']}"}.join("\n").writeToFile(panel.filename, atomically: true, encoding: TextEncoding[@appInfoObjCtl.content['encoding']], error: nil)
      end
    })
  end

  
  def windowDidBecomeKey(notification)
    @changeFlag = 0
  end
  
  
  def windowDidResignKey(notification)
    if @changeFlag == 1 && Defaults['replaceCharCheck']
      listItems = ListItemProcesses.new
      listItems.charReplacePrepare
      @changeFlag = 0
    end    
  end
  
  
end






