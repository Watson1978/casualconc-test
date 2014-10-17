
class ConcResultController < NSWindowController
  extend IB
  
  outlet :concTable
  outlet :concContextView
  outlet :contextCheck
  #outlet :concResultAry
  outlet :concExportEncodingView
  outlet :encodingChoice
  outlet :appInfoObjCtl
  outlet :concSortOrderChoices
  
  
  attr_accessor :concSearchWord, :concContextWord, :concExcludeWord, :searchEndTime, :currentConcMode, :currentConcScope, :appInfoObjCtl
  attr_accessor :fileController
  
  def windowNibName
    "ConcResult"
  end
    
  
  def concSort(concResults)
    @concTable.undoManager.removeAllActions
    case @appInfoObjCtl.content['concSortChoice']
    when false
      sortOrder = Array.new
      @appInfoObjCtl.content['concSortSelect'].split("-").each do |label|
        sortOrder << SortOrderLabels[label]
      end
      sortOrder << 21 if sortOrder.length == 3      
      @appInfoObjCtl.content['concSortOrder'] = sortOrder
    when true
      @appInfoObjCtl.content['concSortOrder'] = [@appInfoObjCtl.content['concSort1'],@appInfoObjCtl.content['concSort2'],@appInfoObjCtl.content['concSort3'],@appInfoObjCtl.content['concSort4']]
    end
    sortedItems = @concResultAry.sort_by{|x| [x['sortItems'][@appInfoObjCtl.content['concSortOrder'][0]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][1]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][2]][0],x['sortItems'][@appInfoObjCtl.content['concSortOrder'][3]][0]]}

    @concResultAry.removeObjectsAtIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@concResultAry.length]))      
    @concResultAry = sortedItems
    @concTable.scrollRowToVisible(0)

  end
  
  
  def copyConcLines(sender)
    pasteBoard = NSPasteboard.pasteboardWithName(NSGeneralPboard)
    pasteBoard.declareTypes([NSStringPboardType,NSPasteboardTypeRTF],owner:self)
    
    case sender.tag
    when 0
      copyText = String.new
      @concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes).each do |item|
        if Defaults['concCopyInsertTab']
          copyText << "#{item['kwic'].join("\t")}\n"
        else
          copyText << "#{item['kwic'].join("")}\n"
        end
      end
      pasteBoard.setString(copyText,forType:NSStringPboardType)
      
    when 1
      copyText = NSMutableAttributedString.alloc.init
      colorPosAdjust1 = Defaults['concCopyInsertTab'] ? 1 : 0
      colorPosAdjust2 = Defaults['concCopyInsertTab'] ? 2 : 0
      
      @concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes).each do |item|
        if Defaults['concCopyInsertTab']
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join("\t"),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])}).appendAttributedString(NSMutableAttributedString.alloc.initWithString("\n"))
        else
          concLine = NSMutableAttributedString.alloc.initWithString(item['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])}).appendAttributedString(NSMutableAttributedString.alloc.initWithString("\n"))
        end
        if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
          concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [item['kwic'][0].length + colorPosAdjust1,item['kwic'][1].length])        
        end
        if Defaults['concCopyContextColor']
          @appInfoObjCtl.content['concSortOrder'].each_with_index do |orderPos,idx|
            if orderPos > 10
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: [item['sortItems'][orderPos][1][0] + colorPosAdjust2,item['sortItems'][orderPos][1][1]])
            else
              concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: item['sortItems'][orderPos][1])
            end
          end
        end
        if Defaults['concCopyContextStyle'] && !item['contextMatch'].nil?
          if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
            item['contextMatch'].each do |contextMatch|
              if contextMatch[0] > item['kwic'].length
                concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: [contextMatch[1][0] + colorPosAdjust2,contextMatch[1][1]])
              else
                concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: contextMatch[1])
              end
            end
          else
            item['contextMatch'].each do |contextMatch|
              if contextMatch[0] > item['kwic'].length
                concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range:  [contextMatch[1][0] + colorPosAdjust2,contextMatch[1][1]])
              else
                concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: contextMatch[1])
              end
            end
          end
        end
        copyText.appendAttributedString(concLine)
      end
      pasteBoard.setData(copyText.RTFFromRange([0,copyText.length],documentAttributes:nil),forType:NSRTFPboardType)
    end
  end
  
  
  def exportResult(sender)
    return if @concResultAry.length == 0
    
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the file to export Concordance results.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAccessoryView(@concExportEncodingView)
    panel.setAllowedFileTypes(Defaults['exportKeepFontInfo'] ? [:rtf] : [:txt])
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['exportDefaultFolder']))    
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        outText = Array.new
        outText << "Concordance Output: #{NSDate.date.description.sub(/ [+-]\d+$/,"")}"
        searchWordInfo = ""
        searchWordInfo += "Search Word: #{@concSearchWord}" if !@concSearchWord.nil?
        searchWordInfo += "\tContext Word: #{@concContextWord}" if !@concContextWord.nil?
        searchWordInfo += "\tContext Exclude Word: #{@concExcludeWord}" if Defaults['contextExcludeCheck'] && !@concExcludeWord.nil?
        outText << searchWordInfo
        outText << ""
        if Defaults['exportKeepFontInfo']
          colorPosAdjust1 = Defaults['concExportInsertTab'] ? 1 : 0
          colorPosAdjust2 = Defaults['concExportInsertTab'] ? 2 : 0
          initLine = "\tKWIC"
          initLine += "\tFile Name" if Defaults['panel.filename'] && !(Defaults['corpusMode'] == 0 && Defaults['mode'] == 1)
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
            concLine.appendAttributedString(NSAttributedString.alloc.initWithString("\t#{item['filename']}")) if Defaults['panel.filename'] && !item['filename'].nil?
            concLine.appendAttributedString(NSAttributedString.alloc.initWithString("\t#{item['corpus']}")) if Defaults['concExportCDName'] && !item['corpus'].nil?

            outAttrText.appendAttributedString(concLine)
          end
          outAttrText.RTFFromRange([0,outAttrText.length], documentAttributes: nil).writeToFile(panel.filename, atomically: true)
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
          initLine += "\tFile Name" if Defaults['panel.filename'] && !(Defaults['corpusMode'] == 0 && Defaults['mode'] == 1)
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
            outLine += "\t#{item['filename']}" if Defaults['panel.filename'] && !item['filename'].nil?
            outLine += "\t#{item['corpus']}" if Defaults['concExportCDName'] && !item['corpus'].nil?
            outText << outLine
          end
          outText.join("\n").writeToFile(panel.filename, atomically: true, encoding: FileEncoding[@encodingChoice.indexOfSelectedItem], error: nil)
        end
      end
    })
    
  end
  
  def changeExportFileType(sender)
    sender.window.setAllowedFileTypes(sender.state == 1 ? [:rtf] : [:txt])
  end
  

  
  def saveResults(sender)
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the file to save the Concordance result.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAllowedFileTypes([:concdata])
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['exportDefaultFolder']))    
    panel.beginSheetModalForWindow(self.window,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        @progressBar.startAnimation(nil)
        aryToSave = @concResultAry.mutableCopy
        aryToSave.unshift({'currentMode' => @currentConcMode, 'currentScope' => @currentConcScope, 'searchWord' => @concSearchWord, 'contextWord' => @concContextWord.to_s, 'exclWord' => @concExcludeWord.to_s})
        aryToSave.writeToFile(panel.filename, atomically: true)
        @progressBar.stopAnimation(nil)
      end
    })
  end
  
    

  def deleteConcLine(sender)
    @concTable.undoManager.registerUndoWithTarget(self, selector: "addBackConcLines:", object: [@concResultAry.objectsAtIndexes(@concTable.selectedRowIndexes),@concTable.selectedRowIndexes])
    @concResultAry.removeObjectsAtIndexes(@concTable.selectionIndexes)        
  end
  
  def addBackConcLines(deletedItems)
    @concResultAry.insertObjects(deletedItems[0], atIndexes: deletedItems[1])
  end




  def numberOfRowsInTableView(tableView)
    case tableView
    when @concTable
      @concResultAry ? @concResultAry.length : 0
    end
	end
		

	def tableView(tableView,objectValueForTableColumn:col,row:row)
    case col
    when tableView.tableColumnWithIdentifier('id')
      row + 1
    when tableView.tableColumnWithIdentifier('kwic')
      concLine = NSMutableAttributedString.alloc.initWithString(@concResultAry[row]['kwic'].join(""),attributes:{NSFontAttributeName => NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']}", size: Defaults['concFontSize'])})
      if !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
        concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: [@concResultAry[row]['kwic'][0].length,@concResultAry[row]['kwic'][1].length])
      end
      @appInfoObjCtl.content['concSortOrder'].each_with_index do |item,idx|
        concLine.addAttribute(NSForegroundColorAttributeName, value: NSUnarchiver.unarchiveObjectWithData(Defaults["concContextColor#{idx+1}"]).colorUsingColorSpaceName(NSCalibratedRGBColorSpace), range: @concResultAry[row]['sortItems'][item][1])
      end
      if not @concResultAry[row]['contextMatch'].nil?
        if Defaults['concContextWordStyle'] == 0 || !NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']).nil?
          @concResultAry[row]['contextMatch'].each do |item|
            concLine.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyleThick, range: item)
          end
        else
          @concResultAry[row]['contextMatch'].each do |item|
            concLine.addAttribute(NSFontAttributeName, value: NSFont.fontWithName("#{Defaults['concFontAry'][Defaults['concFontType']]['fontName']} Bold", size: Defaults['concFontSize']), range: item[1])
          end
        end
      end
      concLine
    when tableView.tableColumnWithIdentifier('filename')
      @concResultAry[row]['filename']
    when tableView.tableColumnWithIdentifier('corpus')
      @concResultAry[row]['corpus']
    end
	end


  
	def tableViewSelectionDidChange(notification)
	  case notification.object
    when @concTable
      self.updatePreview(nil)
    end
  end

  
  def updatePreview(sender)
    if Defaults['concContextViewCheck'] != true || @concTable.selectedRow == -1
      @concContextView.setString("")
      return
    end
    item = @concResultAry[@concTable.selectedRow]
    case NSApp.delegate.currentConcMode
    when 1
      if NSApp.delegate.inputText.string == ""
        alert = NSAlert.alertWithMessageText("The text box in File View is empty.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"Please switch to Text mode and copy/paste the original text in the text box in File View.")
        alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
        return
      end
      case NSApp.delegate.currentConcScope
      when 1
        @concContextView.setString(NSApp.delegate.inputText.string)
        keyPos = item['keyPos']
      when 0
        contentText = NSApp.delegate.inputText.string
        contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
        keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        @concContextView.setString(contentText) if @concContextView.string != contentText
      when 2
        @concContextView.setString(NSApp.delegate.inputText.string)
        keyPos = item['keyPos']
      end
    when 3
      if !NSFileManager.defaultManager.fileExistsAtPath(item['dbPath'])
        alert = NSAlert.alertWithMessageText("The original database file is missing.",
                                            defaultButton:"OK",
                                            alternateButton:nil,
                                            otherButton:nil,
                                            informativeTextWithFormat:"Please check if the original database file is in the same directory.")
        alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
        return      
      end
      db = FMDatabase.databaseWithPath(item['dbPath'])
      case NSApp.delegate.currentConcScope
      when 1
        db.open
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            contentText += results.resultDictionary['text'] + "\n\n"
          end
          results.close
          keyPos = item['keyPos']
          @currentDispItem = [item['path']]
          @concContextView.setString(contentText)
        db.close
      when 0
      	db.open
          textAry = Array.new
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            textAry << [results.resultDictionary['text'],results.resultDictionary['id']]
          end
          results.close
          preText = textAry.select{|x| x[1].to_i < item['entryID']}.last(50).map{|x| x[0]}.join("\n\n")
          restText = textAry.select{|x| x[1].to_i >= item['entryID']}.first(50).map{|x| x[0]}.join("\n\n")
          keyPos = [item['keyPos'][0] + preText.length + 2,item['keyPos'][1]]
          @currentDispItem = [item['path']]
          @concContextView.setString(preText + "\n\n" + restText)
        db.close
      when 2
      	db.open
          textAry = Array.new
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",item['fileID'])
          while results.next
            textAry << [results.resultDictionary['text'],results.resultDictionary['id']]
          end
          preText = textAry.select{|x| x[1].to_i < item['entryID']}.last(50).map{|x| x[0]}.join("\n\n")
          restText = textAry.select{|x| x[1].to_i >= item['entryID']}.first(50).map{|x| x[0]}.join("\n\n")
          keyPos = [item['keyPos'][0] + preText.length + 2,item['keyPos'][1]]
          @currentDispItem = [item['path']]
          @concContextView.setString(preText + "\n\n" + restText)
          results.close
        db.close          
      end
    else
      case NSApp.delegate.currentConcScope
      when 1
        if [item['path'],item['encoding']] != @currentDispItem #|| @currentDispItem.nil?
          tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
          contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
          @currentDispItem = [item['path'],item['encoding']]
          @concContextView.setString(contentText)
        end
        keyPos = item['keyPos']
      when 0
        if [item['path'],item['encoding']] != @currentDispItem #|| @currentDispItem.nil?
          tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
          contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
          contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
          keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
          @currentDispItem = [item['path'],item['encoding']]
          @concContextView.setString(contentText)
        else
          contentText = @concContextView.string
          contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
          keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        end
      when 2
        tagsettings = Defaults['applyTagsToPreview'] ? @fileController.tagPreparation : []
        contentText = @fileController.readFileContents(item['path'],item['encoding'],"display",tagsettings,nil)
        contentText.match(Regexp.new(Regexp.escape(contentText.lines.grep(Regexp.new(Regexp.escape(item['kwic'].join("").strip).gsub(/\\?\s+/,"\\s+")))[0])))
        keyPos = [$`.length + item['keyPos'][0],item['keyPos'][1]]
        @currentDispItem = [item['path'],item['encoding']]
        @concContextView.setString(contentText)
      end
    end
    @concContextView.setTextColor(NSColor.blackColor)
    @concContextView.setFont(NSFont.fontWithName("Lucida Grande", size: Defaults['concContextViewFontSize']))
    @concContextView.setTextColor(NSColor.redColor, range: keyPos)
    @concContextView.setFont(NSFont.fontWithName("Lucida Grande Bold", size: Defaults['concContextViewFontSize']), range: keyPos)
    @concContextView.scrollRangeToVisible(keyPos)
  end	
	
	
	def windowShouldClose(window)
    if window == self.window
      NSApp.delegate.concWindows.delete_if{|x| x[0] == @searchEndTime}
      return true
    end
  end
  
  
	
end
