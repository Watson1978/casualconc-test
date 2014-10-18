#
#  WCResultWindowController.rb
#  CasualConc
#
#  Created by Yasu on 10/12/14.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class WCResultWindowController < NSWindowController

  attr_accessor :wcAryCtl, :wcTable, :wcResultInfo, :types, :tokens, :files, :encodingChoice, :saveOptionChoice, :saveOptionView
  attr_accessor :progressBar, :currentWCCDs, :currentWCMode
  
  def windowNibName
    "WCResult"
  end
  
  
  def awakeFromNib
    @progressBar.setDisplayedWhenStopped(false)
    @progressBar.setUsesThreadedAnimation(true)

  end
  
  
  def saveResult(sender)
    panel = NSSavePanel.savePanel
    panel.setAccessoryView(@saveTableChoiceView)    
    panel.setMessage("Select a folder and name the file to save the Word/n-gram list.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAllowedFileTypes([:wcdata])
    panel.beginSheetForDirectory(Defaults['exportDefaultFolder'], 
          file: nil, 
          modalForWindow: self.window, 
          modalDelegate: self, 
          didEndSelector: "resultSaveDidEnd:returnCode:contextInfo:", 
          contextInfo: nil)
    
  end
  
  
  def resultSaveDidEnd(panel,returnCode:returnCode,contextInfo: info)
    panel.close
    if returnCode == 1
      @progressBar.startAnimation(nil)

      currentPredicate = @wcAryCtl.filterPredicate
      @wcAryCtl.setFilterPredicate(nil)
      aryToSave = @wcAryCtl.arrangedObjects.mutableCopy
      @wcAryCtl.setFilterPredicate(currentPredicate)
      aryToSave.unshift({'wcType' => @wcTable.tableColumnWithIdentifier('word').headerCell.stringValue,'types' => @types,'tokens' => @tokens,'files' => @files,'statsLabel' => @wcTable.tableColumnWithIdentifier('stats').headerCell.stringValue})
      aryToSave.writeToFile(panel.filename, atomically: true)

      @progressBar.stopAnimation(nil)
    end
  end
  
  
  def exportResult(sender)
    panel = NSSavePanel.savePanel
    
    panel.setMessage("Select a folder and name the file to save the Word/n-gram list.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAccessoryView(@saveOptionView)
    panel.setAllowedFileTypes([:txt])
    panel.beginSheetForDirectory(Defaults['exportDefaultFolder'], 
          file: nil, 
          modalForWindow: self.window, 
          modalDelegate: self, 
          didEndSelector: "exportPanelDidEnd:returnCode:contextInfo:", 
          contextInfo: nil)
    
  end
    
  def exportPanelDidEnd(panel,returnCode:returnCode,contextInfo: info)
    panel.close
    if returnCode == 1
      @progressBar.startAnimation(nil)
      
      outText = []

      case @saveOptionChoice.indexOfSelectedItem
      when 0
        outText << "Word List Output:  #{NSDate.date.description.sub(/ [+-]\d+$/,"")}\n#{@wcResultInfo.stringValue}"
        if @currentWCMode[1] == 1
          if @currentWCMode[0] == 0
            outText << "Corpus: #{@currentWCCDs}"
          else
            outText << "Database: #{@currentWCCDs}"
          end
        end
        outText << ""
        wcLabels = "\t#{@wcTable.tableColumnWithIdentifier('word').headerCell.stringValue}\tFrequency\tProportion"
        outText << wcLabels
        outText += @wcAryCtl.arrangedObjects.map{|x| "#{x['rank']}\t#{x['word']}\t#{x['freq']}\t#{sprintf("%.2f%",x['prop'].to_f*100)}"}
      when 1
        outText += @wcAryCtl.arrangedObjects.map{|x| "#{x['word']}\t#{x['freq']}"}      
      when 2
        outText << "Word List Output:  #{NSDate.date.description.sub(/ [+-]\d+$/,"")}\t#{@wcResultInfo.stringValue}"
        if @currentWCMode[1] == 1
          if @currentWCMode[0] == 0
            outText << "Corpus: #{@currentWCCDs}"
          else
            outText << "Database: #{@currentWCCDs}"
          end
        end
        outText << "\t#{@wcTable.tableColumnWithIdentifier('word').headerCell.stringValue}\tFrequency\tProportion\tIn File\tIn Corpus\t#{@wcTable.tableColumnWithIdentifier('stats').headerCell.stringValue}\tLemma Words\tContent Words"

        outText += @wcAryCtl.arrangedObjects.map{|x| "#{x['rank']}\t#{x['word']}\t#{x['freq']}\t#{sprintf("%.2f%",x['prop'].to_f)}\t#{x['inFile'].to_s}\t#{x['inCorpus'].to_s}\t#{sprintf("%.3f",x['stats'].to_f)}\t#{x['lemma'].to_s}\t#{x['contentWords'].to_s}"}
      end
      outText.join("\n").writeToFile(panel.filename, atomically: true, encoding: FileEncoding[@encodingChoice.indexOfSelectedItem], error: nil)

      @progressBar.stopAnimation(nil)

    end
  end
  
  
end
