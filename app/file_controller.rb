class FileController
  extend IB
  
  outlet :mainWindow
  outlet :currentFileListAry
  outlet :currentFileListTable
  outlet :filesToAddAry
  outlet :corpusListAry
  outlet :dbListAry
  outlet :indexedDBListAry
  outlet :contentListAry
  outlet :encodingView
  outlet :plotBtn
  outlet :fileContentProgressCircle
  outlet :selectedCorpusAryCtl
  outlet :selectedDatabaseAryCtl
  outlet :fileTable
  outlet :filesToAddTable
  outlet :corporaListTable
  outlet :databaseListTable
  outlet :indexedDatabaseListTable  
  outlet :cdContentsTable
  outlet :filePreviewText
  outlet :advFilePreviewText

  outlet :createNewCDBtn
  outlet :nameNewCDPanel

  outlet :appInfoObjCtl
  
  attr_accessor :fileAry, :filePreview, :cdListAry, :cdListTable, :selectedCDAry, :cdSelection, :cdListPath, :cdLabel
  attr_accessor :corpusListAry, :dbListAry
  
  
  def awakeFromNib
    @fileManager = NSFileManager.defaultManager
    @fileAry = [@currentFileListAry,@filesToAddAry,@contentListAry]
    @filePreview = [@filePreviewText,@advFilePreviewText,@advFilePreviewText]

    @cdListAry = [@corpusListAry,@dbListAry,@indexedDBListAry]
    @cdListTable = [@corporaListTable,@databaseListTable]
    @selectedCDAry = [@selectedCorpusAryCtl,@selectedDatabaseAryCtl]
    @cdSelection = [['wcLeftCorpusSelection','wcRightCorpusSelection','clLeftCorpusSelection','clRightCorpusSelection','concCorpusSelection','collocCorpusSelection'],['wcLeftDatabaseSelection','wcRightDatabaseSelection','clLeftDatabaseSelection','clRightDatabaseSelection','concDatabaseSelection','collocDatabaseSelection']]
    @cdListPath = ["#{CDListFolderPath}/corpuslist","#{CDListFolderPath}/dblist","#{CDListFolderPath}/idxdblist"]
    @cdLabel = ["Corpus","Database File","Indexed Database File"]


    @currentFileListTable.registerForDraggedTypes([NSFilenamesPboardType])
		@currentFileListTable.setDraggingSourceOperationMask(NSDragOperationEvery,forLocal:true)
    @filesToAddTable.registerForDraggedTypes([NSFilenamesPboardType])
		@filesToAddTable.setDraggingSourceOperationMask(NSDragOperationEvery,forLocal:true)
		@corporaListTable.registerForDraggedTypes([TableContentType])
	  @corporaListTable.setDraggingSourceOperationMask(NSDragOperationEvery,forLocal:true)
		@databaseListTable.registerForDraggedTypes([TableContentType,NSFilenamesPboardType])
	  @databaseListTable.setDraggingSourceOperationMask(NSDragOperationEvery,forLocal:true)
    @indexedDatabaseListTable.registerForDraggedTypes([TableContentType,NSFilenamesPboardType])
    @indexedDatabaseListTable.setDraggingSourceOperationMask(NSDragOperationEvery,forLocal:true)
	  @fileContentProgressCircle.setDisplayedWhenStopped(false)
    @fileContentProgressCircle.setUsesThreadedAnimation(true)    

    @filePreviewText.setAutomaticSpellingCorrectionEnabled(false)
    @filePreviewText.setAutomaticDashSubstitutionEnabled(false)
    @filePreviewText.setAutomaticDataDetectionEnabled(false)
    @filePreviewText.setAutomaticQuoteSubstitutionEnabled(false)
    @filePreviewText.setAutomaticTextReplacementEnabled(false)

    @advFilePreviewText.setAutomaticSpellingCorrectionEnabled(false)
    @advFilePreviewText.setAutomaticDashSubstitutionEnabled(false)
    @advFilePreviewText.setAutomaticDataDetectionEnabled(false)
    @advFilePreviewText.setAutomaticQuoteSubstitutionEnabled(false)
    @advFilePreviewText.setAutomaticTextReplacementEnabled(false)

  end
  
  def addFiles(sender)
    panel = NSOpenPanel.openPanel
    panel.setAllowsMultipleSelection(true)
    panel.setCanChooseFiles(true)
    panel.setCanChooseDirectories(true)
    panel.setAccessoryView(@encodingView)
    panel.setMessage(NSLocalizedString("Select file(s) to add"))
    case Defaults['corpusFileTypeChoice']
    when 0
      @acceptFileTypes = ['txt']
    when 1
      @acceptFileTypes = Array.new
      AcceptFileTypes.each_with_index do |type,idx|
        @acceptFileTypes << AcceptFileExtensions[idx] if Defaults[type]
      end
      @acceptFileTypes.flatten!
    end
    panel.setAllowedFileTypes(@acceptFileTypes)
    panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
      panel.close
      if result == 1
        filesToAdd = self.addFilesToList(panel.filenames,"btn")
        @fileAry[Defaults['corpusMode']].addObjects(filesToAdd)
        #@plotBtn.setEnabled(false) if !@plotBtn.isHidden && @plotBtn.isEnabled
      end
    })    
  end
  
  
  def addFilesToList(fileAry,source)
    filesToAdd = Array.new
    exteions = Regexp.new("\\.(?:#{@acceptFileTypes.join("|")})") if not @acceptFileTypes.nil?
    fileAry.each do |path|
      next if File.basename(path).match(/^\./)
      if FileTest.file?(path)
        next if File.basename(path).downcase.match(/^\./)
        next if @fileAry[Defaults['corpusMode']].arrangedObjects.select{|x| x['path'] == path}.length > 0
        case File.extname(path).downcase
        when ".doc",".docx",".pdf",".htm",".html",".webarchive",".rtf",".rtfd",".odt",".sxw"
          filesToAdd << {'path' => path, 'filename' => File.basename(path), 'directory' => File.dirname(path), 'encoding' => 99} if Defaults['mode'] != 2
        else
          case source
          when "btn"
            filesToAdd << {'path' => path, 'filename' => File.basename(path), 'directory' => File.dirname(path), 'encoding' => Defaults['fileEncoding']}
          when "drag"
            filesToAdd << {'path' => path, 'filename' => File.basename(path), 'directory' => File.dirname(path), 'encoding' => Defaults['defaultEncoding']}
          end
        end     
      else
        enm = NSFileManager.defaultManager.enumeratorAtPath(path)
        while (fn = enm.nextObject)
          filename = "#{path}/#{fn}"
          next if File.basename(filename).downcase.match(/^\./) || File.directory?(filename)
          next if @fileAry[Defaults['corpusMode']].arrangedObjects.select{|x| x['path'] == filename}.length > 0
          case File.extname(filename).downcase
          when ".doc",".docx",".pdf",".htm",".html",".webarchive",".rtf",".rtfd",".odt",".sxw"
            filesToAdd << {'path' => filename, 'filename' => File.basename(filename), 'directory' => File.dirname(filename), 'encoding' => 99} if Defaults['mode'] != 2
          else
            case source
            when "btn"
              filesToAdd << {'path' => filename, 'filename' => File.basename(filename), 'directory' => File.dirname(filename), 'encoding' => Defaults['fileEncoding']}
            when "drag"
              filesToAdd << {'path' => filename, 'filename' => File.basename(filename), 'directory' => File.dirname(filename), 'encoding' => Defaults['defaultEncoding']}
            end
          end     
        end
      end
    end
    return filesToAdd
  end
  
  
  def removeFiles(sender)
    @fileAry[sender.tag].removeObjects(@fileAry[sender.tag].selectedObjects)
    @plotBtn.setEnabled(false) if sender.tag == 0 && !@plotBtn.isHidden && @plotBtn.isEnabled && sender.tag == 0
  end
  
  
  def clearTable(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to clear the table?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This process cannot be undone.")
    alert.buttons[1].setKeyEquivalent("\e")
    userChoice = alert.runModal
    case userChoice
    when -1
      return
    when 1
      @fileAry[sender.tag].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@fileAry[sender.tag].arrangedObjects.length]))      
      @plotBtn.setEnabled(false) if !@plotBtn.isHidden && @plotBtn.isEnabled && sender.tag == 0
    end   
  end
  
  
  
  def readFileContents(path,encoding,source,tagSettings,searchWord)

    origString = case File.extname(path).downcase
    when ".doc", ".docx", ".rtf", ".rtfd", ".html", ".htm", ".webarchive", ".odt", ".sxw"
      NSMutableAttributedString.alloc.initWithPath(path, documentAttributes: nil).string
      #NSAttributedString.alloc.initWithPath(path, documentAttributes: nil).string.UTF8String.force_encoding("UTF-16BE")
    when ".pdf"
      PDFDocument.alloc.initWithURL(NSURL.fileURLWithPath(path)).string.gsub(/\r\n|\r/,"\n") unless PDFDocument.alloc.initWithURL(NSURL.fileURLWithPath(path)).nil?
    else
      if encoding == 0
        File.read(path)
      else
        NSMutableString.alloc.initWithContentsOfFile(path,encoding:TextEncoding[encoding],error:nil)
      end
    end
    if searchWord.nil? || !origString.match(searchWord).nil?
      origString.gsub!(NSApp.delegate.relaceChars[0]){|x| NSApp.delegate.relaceChars[1][$&]} if Defaults['replaceCharCheck'] && Defaults['replaceCharsAry'].length > 0
      origString = self.tagApplication(origString,tagSettings,source,path) if Defaults['tagModeEnabled'] && (source != "display" || (source == "display" && Defaults['applyTagsToPreview'])) && (File.extname(path).downcase == ".txt" || File.extname(path).downcase == "")      
    else
      origString = ""
    end
    return origString
  end
  
  
  
  def addNewCDEntry(sender)
    @appInfoObjCtl.content.removeObjectForKey('newCDName') if not @appInfoObjCtl.content['newCDName'].nil?
    @createNewCDBtn.setTag(sender.tag)
    @mainWindow.beginSheet(@nameNewCDPanel,completionHandler:Proc.new { |returnCode| })    
  end
  
  
  def createCDEntry(sender)
    if sender.tag == 2
      @mainWindow.endSheet(@nameNewCDPanel)
      return
    end
    
    newCDName = @appInfoObjCtl.content['newCDName'].strip
    if @cdListAry[sender.tag].arrangedObjects.select{|x| x['name'].downcase == newCDName.downcase}.length > 0
      alert = NSAlert.alertWithMessageText("This name is already used.",
                                          defaultButton:"OK",
                                          alternateButton:nil,
                                          otherButton:nil,
                                          informativeTextWithFormat:"Please use another name.")
      alert.beginSheetModalForWindow(@nameNewCDPanel,completionHandler:Proc.new { |returnCode| })
      return
    end
    case sender.tag
    when 0
      self.createCorpusEntryProcess(newCDName)
    when 1
      self.mergeCDProcess(newCDName)
    end
  end


  def createCorpusEntryProcess(newCDName)
    @mainWindow.endSheet(@nameNewCDPanel)
    @corpusListAry.addObject({'name' => newCDName,'files' => @filesToAddAry.arrangedObjects.length, 'check' => false, 'path' => "#{CorpusFolderPath}/#{newCDName}"})
    @filesToAddAry.arrangedObjects.map{|x| x.merge({"corpus" => newCDName})}.writeToFile("#{CorpusFolderPath}/#{newCDName}", atomically: true)
    @corpusListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/corpuslist", atomically: true)
    @filesToAddAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@filesToAddAry.arrangedObjects.length]))
    @appInfoObjCtl.content.removeObjectForKey('newCDName')    
  end



  def addFilesToCD(sender)
    selectedItem = @cdListAry[sender.tag].arrangedObjects[@cdListAry[sender.tag].selectionIndex]
    alert = NSAlert.alertWithMessageText("Do you want to proceed?",
                                        defaultButton:"Proceed",
                                        alternateButton:nil,
                                        otherButton:"Abort",
                                        informativeTextWithFormat:"You are adding files to '#{selectedItem['name']}'. This process cannot be undone.")
    
    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
      if returnCode == 1
        selectedItem = @cdListAry[Defaults['mode']].arrangedObjects[@cdListAry[Defaults['mode']].selectionIndex]
        @filesSkipped = Array.new
        case Defaults['mode']
        when 0
          currentCorpusFiles = NSMutableArray.arrayWithContentsOfFile(selectedItem['path'])
      
          filesToAdd = Array.new
          @filesToAddAry.arrangedObjects.each do |item|
            if currentCorpusFiles.select{|x| x['path'] == item['path']}.length > 0
              @filesSkipped << item['filename']
              next
            end
            filesToAdd << item
          end
      
          currentCorpusFiles.addObjectsFromArray(filesToAdd.map{|x| x.merge({"corpus" => selectedCorpus['name']})})

          currentCorpusFiles.writeToFile(selectedItem['path'], atomically: true)
          selectedItem['files'] += selectedItem['files'] + filesToAdd.length

          #@contentListAry.addObjects(filesToAdd) if @contentListAry.arrangedObjects.length > 0
        when 1
          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(@filesToAddAry.arrangedObjects.length)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded
          wordReg = Regexp.new(WildWordProcess.new("dbCreation").wildWord,Regexp::IGNORECASE)
          tokens = selectedItem['tokens']
          tagProcessItems = self.tagPreparation
          fileID = 0
          db = FMDatabase.databaseWithPath(selectedItem['path'])
          db.open
            db.beginTransaction
              results = db.executeQuery("SELECT DISTINCT path,encoding,file_id FROM conc_data")
              allFiles = Array.new
              while results.next
                allFiles << results.resultDictionary['path']
              end
              results.close
              fileID = db.intForQuery("SELECT max(file_id) From conc_data") + 1

              @filesToAddAry.arrangedObjects.each do |item|
                autorelease_pool {
                  if allFiles.include?(item['path'])
                    @filesSkipped << item['path']
                    next
                  end
                  inText = self.readFileContents(item['path'],item['encoding'],"dbCreate",tagProcessItems,nil)
                  next if (fileTokens = inText.scan(wordReg).length) == 0
                  tokens += fileTokens
                  inText.lines.each do |parag|
                    parag.strip!
                    next if parag == ""
                    db.executeUpdate("INSERT INTO conc_data (id,file_name,text,path,file_id,encoding) values (null,?,?,?,?,?)",item['filename'],parag,item['path'],fileID,item['encoding'])
                  end
                }
                fileID += 1
                NSApp.delegate.progressBar.incrementBy(1.0)
              end
              @dbListAry.arrangedObjects[@dbListAry.selectionIndex]['tokens'] = tokens
              @dbListAry.arrangedObjects[@dbListAry.selectionIndex]['files'] = db.intForQuery("SELECT count(DISTINCT file_id) FROM conc_data")
            db.commit
          db.close
        end
        @cdListAry[Defaults['mode']].arrangedObjects.writeToFile(@cdListPath[Defaults['mode']], atomically: true)
        @filesToAddAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@filesToAddAry.arrangedObjects.length]))
        NSApp.delegate.progressBar.setIndeterminate(true)
        NSApp.delegate.progressBar.displayIfNeeded
      
        if @filesSkipped.length > 0
          alert = NSAlert.alertWithMessageText("#{@filesSkipped.length} files were not added.",
                                              defaultButton:"OK",
                                              alternateButton:"Check",
                                              otherButton:nil,
                                              informativeTextWithFormat:"These files are already in the '#{selectedItem['name']}'.")

          alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
            if returnCode == -1
              alert2 = NSAlert.alertWithMessageText("These files are skipped.",
                                                  defaultButton:"OK",
                                                  alternateButton:nil,
                                                  otherButton:nil,
                                                  informativeTextWithFormat:@filesSkipped.map{|x| File.basename(x)}.sort.join("\n"))

              alert2.runModal
            end
            
          })

        end
      end
      self.refreshFileListTable(nil)
      
    })
    
  end
      
  
  
  def deleteFilesFromCD(sender)
    selectedItem = @cdListAry[Defaults['mode']].arrangedObjects[@cdListAry[Defaults['mode']].selectionIndex]
    alert = NSAlert.alertWithMessageText("Do you want to proceed?",
                                        defaultButton:"Proceed",
                                        alternateButton:nil,
                                        otherButton:"Abort",
                                        informativeTextWithFormat:"You are deleting the selected files from '#{selectedItem['name']}'. This process cannot be undone.")

    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
      selectedItem = @cdListAry[Defaults['mode']].arrangedObjects[@cdListAry[Defaults['mode']].selectionIndex]
      if returnCode == 1
        case Defaults['mode']
        when 0
          fileNum = @contentListAry.selectionIndexes.count
          if selectedItem['files'] - fileNum == 0
            NSFileManager.defaultManager.removeItemAtPath(selectedItem['path'], error: nil)
            @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))
          else
            selectedItem['files'] = selectedItem['files'] - fileNum
            @contentListAry.removeObjectsAtArrangedObjectIndexes(@contentListAry.selectionIndexes)
            @contentListAry.arrangedObjects.writeToFile(selectedItem['path'], atomically: true)
          end        
          @cdListAry[Defaults['mode']].arrangedObjects.writeToFile(@cdListPath[Defaults['mode']], atomically: true)
        when 1
          if @contentListAry.arrangedObjects.length == @contentListAry.selectedObjects.length
            path = @dbListAry.arrangedObjects[@dbListAry.selectionIndex]['path']
            NSWorkspace.sharedWorkspace.performFileOperation(NSWorkspaceRecycleOperation, source: File.dirname(path), destination: NSHomeDirectory().stringByAppendingPathComponent(".Trash"), files: [File.basename(path)], tag: nil)
            @dbListAry.removeObjectsAtArrangedObjectIndexes(@dbListAry.selectionIndexes)
            @dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)
            @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))
          else
            tokens = selectedItem['tokens']
            origFiles = selectedItem['files']
            db = FMDatabase.databaseWithPath(selectedItem['path'])
            db.open
              db.beginTransaction
                @contentListAry.selectedObjects.each do |item|
                  results = db.executeQuery("SELECT * FROM conc_data WHERE file_id = ? ORDER BY id",eachFile['file_id'])
                  tokens = 0
                  while results.next
                    fileTokens += results.resultDictionary['tokens']              
                  end
                  tokens -= fileTokens
                  db.executeUpdate("DELETE FROM conc_data WHERE file_id = ?",item['fileID'])
                end
                @dbListAry.arrangedObjects[@dbListAry.selectionIndex]['tokens'] = tokens                
                @dbListAry.arrangedObjects[@dbListAry.selectionIndex]['files'] = db.intForQuery("SELECT count(DISTINCT file_id) FROM conc_data")
              db.commit
            db.close
            @contentListAry.removeObjectsAtArrangedObjectIndexes(@contentListAry.selectionIndexes)
          end
        end
      end
    })
  end
      


  def mergeCDProcess(newCDName)
    @mainWindow.endSheet(@nameNewCDPanel)
    
    newCorpusArray = Array.new
    @corpusListAry.selectedObjects.each do |corpus|
      newCorpusArray.addObjectsFromArray(NSArray.arrayWithContentsOfFile(corpus['path']))
    end
    
    @corpusListAry.addObject({'name' => newCDName,'files' => newCorpusArray.uniq.length, 'check' => false, 'path' => "#{CorpusFolderPath}/#{newCDName}"})
    newCorpusArray.uniq.writeToFile("#{CorpusFolderPath}/#{newCDName}", atomically: true)
    
    @corpusListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/corpuslist", atomically: true)
    @appInfoObjCtl.content.removeObjectForKey('newCDName')
  end





  def createNewDB(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to creat a database file with the current Tag settings?",
                                        defaultButton:"Proceed",
                                        alternateButton:"Open Preferences",
                                        otherButton:"Abort",
                                        informativeTextWithFormat:"If not, please change Tag Application settings in Preferences.")

    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| 
      case result
      when 1 #default
        case sender.tag
        when 0
          self.startNewDBCreationProcess(self)
        when 1
          self.startNewIndexedDBCreationProcess(self)
        end
      when 0 #alternate
        NSApp.delegate.showPrefWindow(nil)
        NSApp.delegate.prefWindow.prefTab.selectTabViewItemAtIndex(3)
        break
      when -1
        break
      end
    })              
  end
    


  def startNewDBCreationProcess(sender)
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the database file.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAllowedFileTypes([:db])
		panel.setCanCreateDirectories(true)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['databaseDefaultFolder']))
		if sender == self
      panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
        panel.close
        if returnCode == 1
          if @dbListAry.arrangedObjects.select{|x| x['name'].downcase == File.basename(panel.filename,".*").downcase}.length > 0
            alert = NSAlert.alertWithMessageText("The database with the same name is already on the list.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"Please use the name not on the list.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })

            break
          end
      
          tokens = self.createNewDatabaseFile(panel.filename)

          @dbListAry.addObject({'name' => File.basename(panel.filename,".*"),'files' => @filesToAddAry.arrangedObjects.length, 'check' => false, 'path' => panel.filename, 'tokens' => tokens})
          @dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)

          @filesToAddAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@filesToAddAry.arrangedObjects.length]))
          NSApp.delegate.progressBar.stopAnimation(nil)
          NSApp.delegate.progressBar.displayIfNeeded
      
        end
      })
	  else
      panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| 
        panel.close
        if result == 1
      
          if @dbListAry.arrangedObjects.select{|x| x['name'].downcase == File.basename(panel.filename,".*").downcase}.length > 0
            alert = NSAlert.alertWithMessageText("The database with the same name is already on the list.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"Please use the name not on the list.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
      
            return
          end
      
          allFiles = Array.new
          filesToProcess = 0
          @dbListAry.selectedObjects.map{|x| x['files']}.each{|x| filesToProcess += x}

          sql = <<-SQL
CREATE table conc_data (
id integer PRIMARY KEY AUTOINCREMENT,
file_name text,
encoding integer,
text text,
path text,
paragraph integer,
tokens integer,
file_id integer
);
          SQL

          NSApp.delegate.progressBar.setIndeterminate(false)
          NSApp.delegate.progressBar.setMinValue(0.0)  
          NSApp.delegate.progressBar.setMaxValue(filesToProcess)
          NSApp.delegate.progressBar.setDoubleValue(0.0)
          NSApp.delegate.progressBar.displayIfNeeded

          totalFileID = 0
          totalTokens = 0

          db = FMDatabase.databaseWithPath(panel.filename)
          db.open
            db.beginTransaction
              tableCheck = db.executeQuery("SELECT * FROM sqlite_master WHERE type='table'")
              tables = Array.new
              while tableCheck.next
                tables << tableCheck.resultDictionary
              end
              if tables.include?('conc_data')
                db.executeUpdate("DROP TABLE conc_data") 
              end
              db.executeUpdate(sql)
              dbFileInfo = Array.new
              pathAry = Array.new
              @dbListAry.selectedObjects.each_with_index do |item,idx|
                db2 = FMDatabase.databaseWithPath(item['path'])
                db2.open
                  db2.beginTransaction
                    db2Results = db2.executeQuery("SELECT DISTINCT path,encoding,file_id FROM conc_data")
                    while db2Results.next
                      eachFile = db2Results.resultDictionary
                      if pathAry.include?(eachFile['path'])
                        NSApp.delegate.progressBar.incrementBy(1.0)
                        next 
                      end
                      pathAry << eachFile['path']
              
                      db2DataResults = db2.executeQuery("SELECT * FROM conc_data WHERE file_id = ? ORDER BY id",eachFile['file_id'])
                      while db2DataResults.next
                        eachLine = db2DataResults.resultDictionary                      
                        db.executeUpdate("INSERT INTO conc_data (id,file_name,encoding,text,path,file_id,tokens) values (null,?,?,?,?,?,?)",eachLine['file_name'],eachLine['encoding'].to_i,eachLine['text'],eachLine['path'],totalFileID,eachLine['tokens'])
                        totalTokens += eachLine['tokens']
                      end
                      db2DataResults.close
                      totalFileID += 1
                      NSApp.delegate.progressBar.incrementBy(1.0)
                    end
                    db2Results.close
                  db2.commit
                db2.close
              end
            db.commit
          db.close
          @dbListAry.addObject({'name' => File.basename(panel.filename,".*"),'files' => totalFileID, 'check' => false, 'path' => panel.filename, 'tokens' => totalTokens})
          @dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)

          NSApp.delegate.progressBar.setIndeterminate(true)
          NSApp.delegate.progressBar.stopAnimation(nil)
          #NSApp.delegate.progressBar.displayIfNeeded
      
        end
      })
    end
  end



  def createNewDatabaseFile(dbPath)
    NSApp.delegate.progressBar.setIndeterminate(false)
    NSApp.delegate.progressBar.setMinValue(0.0)  
    NSApp.delegate.progressBar.setMaxValue(@filesToAddAry.arrangedObjects.length)
    NSApp.delegate.progressBar.setDoubleValue(0.0)
    NSApp.delegate.progressBar.displayIfNeeded
    wordReg = Regexp.new(WildWordProcess.new("dbCreation").wildWord,Regexp::IGNORECASE)
    tokens = 0
    tagProcessItems = self.tagPreparation
    

    sql = <<-SQL
CREATE table conc_data (
id integer PRIMARY KEY AUTOINCREMENT,
file_name text,
encoding integer,
text text,
path text,
paragraph integer,
tokens integer,
file_id integer
);
    SQL

    db = FMDatabase.databaseWithPath(dbPath)

    db.open
      db.beginTransaction
        tableCheck = db.executeQuery("SELECT * FROM sqlite_master WHERE type='table'")
        tables = Array.new
        while tableCheck.next
          tables << tableCheck.resultDictionary
        end
        if tables.include?('conc_data')
          db.executeUpdate("DROP TABLE conc_data") 
        end
      
        db.executeUpdate(sql)
    
        fileID = 0
        @filesToAddAry.arrangedObjects.each do |item|
          inText = self.readFileContents(item['path'],item['encoding'],"dbCreate",tagProcessItems,nil)
          next if (fileTokens = inText.scan(wordReg).length) == 0
          tokens += fileTokens
          inText.lines.each do |parag|
            parag.strip!
            next if parag == ""
            paraTokens = parag.scan(wordReg).length
            db.executeUpdate("INSERT INTO conc_data (id,file_name,text,path,file_id,encoding,tokens) values (null,?,?,?,?,?,?)",item['filename'],parag,item['path'],fileID,item['encoding'],paraTokens)
          end
          fileID += 1
          NSApp.delegate.progressBar.incrementBy(1.0)
        end      
      db.commit
    db.close
    NSApp.delegate.progressBar.setIndeterminate(true)
    NSApp.delegate.progressBar.startAnimation(nil)
    return tokens
  end


  
  def startNewIndexedDBCreationProcess(sender)
    panel = NSSavePanel.savePanel
    panel.setMessage("Select a folder and name the database file.")
    panel.setCanSelectHiddenExtension(true)
    panel.setAllowedFileTypes([:idb])
		panel.setCanCreateDirectories(true)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['databaseDefaultFolder']))
    panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| 
      panel.close
      if returnCode == 1
        if @indexedDBListAry.arrangedObjects.select{|x| x['name'].downcase == File.basename(panel.filename,".*").downcase}.length > 0
          alert = NSAlert.alertWithMessageText("The database with the same name is already on the list.",
                                              defaultButton:"OK",
                                              alternateButton:nil,
                                              otherButton:nil,
                                              informativeTextWithFormat:"Please use the name not on the list.")

          alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })

          break
        end

        Dispatch::Queue.concurrent.async{
        
          tokens = self.createNewIndexedDatabaseFile(panel.filename)

          Dispatch::Queue.main.async{

            @indexedDBListAry.addObject({'name' => File.basename(panel.filename,".*"),'files' => @filesToAddAry.arrangedObjects.length, 'check' => false, 'path' => panel.filename, 'tokens' => tokens[0]})
            @indexedDBListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/idxdblist", atomically: true)

            @filesToAddAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@filesToAddAry.arrangedObjects.length]))
            NSApp.delegate.progressBar.stopAnimation(nil)
            NSApp.delegate.progressBar.displayIfNeeded
            
            alert = NSAlert.alertWithMessageText("The database file was successfully created.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"#{tokens[1].to_s} sec.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result| })
            
          }
        }
      end
    })
  end
  
  
  def createNewIndexedDatabaseFile(filename)
    NSApp.delegate.progressBar.setIndeterminate(false)
    NSApp.delegate.progressBar.setMinValue(0.0)  
    NSApp.delegate.progressBar.setMaxValue(@filesToAddAry.arrangedObjects.length)
    NSApp.delegate.progressBar.setDoubleValue(0.0)
    NSApp.delegate.progressBar.displayIfNeeded
    
    
    scriptText = NSMutableString.alloc.initWithContentsOfFile("#{ResourcesFolderPath}/indexDBCreator.rb",encoding:TextEncoding[0],error:nil)
    scriptText.gsub!("[FileListPath]","'#{TempFolderPath}/fileList.txt'")
    scriptText.gsub!("[DBFileName]","'#{filename}'")
    scriptText.gsub!("[RESOUCES PATH]",ResourcesFolderPath)
    
    pipe = NSPipe.alloc.init
    task = NSTask.alloc.init
  
    path = "#{TempFolderPath}/rbscript.rb"
  
    scriptText.writeToFile(path, atomically: true, encoding: TextEncoding[0], error: nil)
    fileListText = @filesToAddAry.arrangedObjects.map{|x| x['path']}.join("\n")
    fileListText.writeToFile("#{TempFolderPath}/fileList.txt", atomically: true, encoding: TextEncoding[0], error: nil)
    
  
    task.setLaunchPath("/usr/bin/ruby")
    task.setArguments([path])
    task.setStandardOutput(pipe)

    task.launch
  
    begin
      handle = pipe.fileHandleForReading
      data = handle.readDataToEndOfFile
      rOutput = NSMutableString.alloc.initWithData(data,encoding:NSUTF8StringEncoding)
    rescue Exception => e
      p e
      rOutput =　"An error occurred in the Ruby Script process."
    end

    returnText = rOutput.split("/")
    tokens = returnText[1].to_i
    spentTime = returnText[0].to_f

    NSFileManager.defaultManager.removeItemAtPath(path,error:nil)
    NSFileManager.defaultManager.removeItemAtPath("#{TempFolderPath}/fileList.txt",error:nil)


    NSApp.delegate.progressBar.setIndeterminate(true)
    NSApp.delegate.progressBar.startAnimation(nil)
    
    return [tokens,spentTime]
=begin    



    wordReg = Regexp.new(WildWordProcess.new("dbCreation").wildWord,Regexp::IGNORECASE)
    tokens = 0
    tagProcessItems = self.tagPreparation
    

    sql = <<-SQL
CREATE table full_text_data (
id integer PRIMARY KEY AUTOINCREMENT,
file_name text,
encoding integer,
text blob,
path text,
tokens integer,
file_id integer
);
    SQL

    sql2 = <<-SQL
CREATE table conc_idx_data (
id integer PRIMARY KEY AUTOINCREMENT,
file_name text,
encoding integer,
key text,
left_text text,
right_text text,
l5 text,
l4 text,
l3 text,
l2 text,
l1 text,
r1 text,
r2 text,
r3 text,
r4 text,
r5 text,
keyw text,
l5_pos_loc text,
l5_pos_len text,
l4_pos_loc text,
l4_pos_len text,
l3_pos_loc text,
l3_pos_len text,
l2_pos_loc text,
l2_pos_len text,
l1_pos_loc text,
l1_pos_len text,
key_pos_loc text,
key_pos_len text,
key_local_pos text,
r1_pos_loc text,
r1_pos_len text,
r2_pos_loc text,
r2_pos_len text,
r3_pos_loc text,
r3_pos_len text,
r4_pos_loc text,
r4_pos_len text,
r5_pos_loc text,
r5_pos_len text,
path text,
file_id integer
);
    SQL
    
#=begin
    db = SQLite3::Database.new(filename)
    stopWords = ['the','a','an','is','are','be','was','were','of','in','and','but','for','to','at']
    #NSApp.delegate.stopWords
    tables = Array.new
    db.execute("SELECT * FROM sqlite_master WHERE type='table'") do |row|
      tables << row
    end
    if tables.include?('conc_idx_data')
      db.execute("DROP TABLE conc_idx_data") 
    end
    if tables.include?('full_text_data')
      db.execute("DROP TABLE full_text_data") 
    end
    db.transaction do
      db.execute(sql)
      db.execute(sql2)
    end
    fileID = 0    
    @filesToAddAry.arrangedObjects.each do |item|
      autorelease_pool {
        db.transaction do
          inText = self.readFileContents(item['path'],item['encoding'],"dbCreate",tagProcessItems,nil)
          next if (fileTokens = inText.scan(/\b(?:\w+(?:\'\w+)?)\b/).length) == 0
          tokens += fileTokens
          textData = inText.dataUsingEncoding(NSUTF8StringEncoding)          
          db.execute("INSERT INTO full_text_data (id,file_name,text,path,file_id,encoding,tokens) values (null,?,?,?,?,?,?)",[item['filename'],textData,item['path'],fileID,item['encoding'],fileTokens])

          inText.scan(/\b(?:\w+(?:\'\w+)?)\b/) do
            autorelease_pool {
              key = $1
              keyPos = $`.length
              next if stopWords.include?(key.downcase)
              if $`.length < 80
                leftText = $`
              else
                leftText = $`[-80,80]
              end
              rightText = $'[0,80]
              leftText.gsub!(/\s+/," ")
              rightText.gsub!(/\s+/," ")
              rightText = rightText[0,60]
              if leftText.length < 60
                leftText = " " * (60-leftText.length) + leftText
              else
                leftText = leftText[leftText.length-60,leftText.length]
              end
              leftWords = Array.new
              leftText.downcase.scan(/\b(?:\w+(?:\'\w+)?)\b/) do |word|
                leftWords << [word[0],[$`.length,$&.length]]
              end
              leftWords.reverse!
              if leftWords.length < 6
                (5-leftWords.length).times do |i|
                  leftWords << ["",[0,0]]
                end
              end
              rightWords = Array.new
              rightText.downcase.scan(/\b(?:\w+(?:\'\w+)?)\b/) do |word|
                rightWords << [word[0],[$`.length+60+key.length,$&.length]]
              end
              if rightWords.length < 6
                (5-rightWords.length).times do |i|
                  rightWords << ["",[0,0]]
                end
              end
              dataAry = [File.basename(item['path']),item['encoding'],key,leftText,rightText,keyPos,leftText.length,key.length,leftWords[4][0],leftWords[3][0],leftWords[2][0],leftWords[1][0],leftWords[0][0],key.downcase,rightWords[0][0],rightWords[1][0],rightWords[2][0],rightWords[3][0],rightWords[4][0],leftWords[4][1][0],leftWords[4][1][1],leftWords[3][1][0],leftWords[3][1][1],leftWords[2][1][0],leftWords[2][1][1],leftWords[1][1][0],leftWords[1][1][1],leftWords[0][1][0],leftWords[0][1][1],rightWords[0][1][0],rightWords[0][1][1],rightWords[1][1][0],rightWords[1][1][1],rightWords[2][1][0],rightWords[2][1][1],rightWords[3][1][0],rightWords[3][1][1],rightWords[4][1][0],rightWords[4][1][1],filename,fileID]
              db.execute("INSERT INTO conc_idx_data (id,file_name,encoding,key,left_text,right_text,key_pos_loc,key_local_pos,key_pos_len,l5,l4,l3,l2,l1,keyw,r1,r2,r3,r4,r5,l5_pos_loc,l5_pos_len,l4_pos_loc,l4_pos_len,l3_pos_loc,l3_pos_len,l2_pos_loc,l2_pos_len,l1_pos_loc,l1_pos_len,r1_pos_loc,r1_pos_len,r2_pos_loc,r2_pos_len,r3_pos_loc,r3_pos_len,r4_pos_loc,r4_pos_len,r5_pos_loc,r5_pos_len,path,file_id) values (null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",dataAry)
            }
          end
        end
      }
      fileID += 1
      NSApp.delegate.progressBar.incrementBy(1.0)
    end
#=end

    NSApp.delegate.progressBar.setIndeterminate(true)
    NSApp.delegate.progressBar.startAnimation(nil)
    return tokens
=end
  end
  
  
  
  def removeCDFromList(sender)
    alert = NSAlert.alertWithMessageText("Are you sure you want to delete selected item(s)?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This process cannot be undone.")

    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode|
      if returnCode == 1
        case Defaults['mode']
        when 0
          @corpusListAry.selectedObjects.each do |item|
            NSFileManager.defaultManager.removeItemAtPath(item['path'], error: nil)
          end
          @corpusListAry.removeObjectsAtArrangedObjectIndexes(@corpusListAry.selectionIndexes)
          @corpusListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/corpuslist", atomically: true)
        when 1,2
          self.removeDBFromList(nil)
        end
        self.corpusSelectionChanged(nil)
      end
    })
  end
  
  

  
  def removeDBFromList(sender)
    alert = NSAlert.alertWithMessageText("Do you want to move the selected database files to Trash?",
                                        defaultButton:"Yes",
                                        alternateButton:nil,
                                        otherButton:"No",
                                        informativeTextWithFormat:"This process cannot be undone.")

    alert.buttons[1].setKeyEquivalent("\e")
    alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode|
      if returnCode == 1
        case Defaults['mode']
        when 1
          @dbListAry.selectedObjects.map{|x| x['path']}.uniq.each do |item|
            NSWorkspace.sharedWorkspace.performFileOperation(NSWorkspaceRecycleOperation, source: File.dirname(item), destination: NSHomeDirectory().stringByAppendingPathComponent(".Trash"), files: [File.basename(item)], tag: nil)
          end      
          @dbListAry.removeObjectsAtArrangedObjectIndexes(@dbListAry.selectionIndexes)
          @dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)
        when 2
          @indexedDBListAry.selectedObjects.map{|x| x['path']}.uniq.each do |item|
            NSWorkspace.sharedWorkspace.performFileOperation(NSWorkspaceRecycleOperation, source: File.dirname(item), destination: NSHomeDirectory().stringByAppendingPathComponent(".Trash"), files: [File.basename(item)], tag: nil)
          end      
          @indexedDBListAry.removeObjectsAtArrangedObjectIndexes(@indexedDBListAry.selectionIndexes)
          @indexedDBListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/idxdblist", atomically: true)
        end
      elsif returnCode == -1
        case Defaults['mode']
        when 1
          @dbListAry.removeObjectsAtArrangedObjectIndexes(@dbListAry.selectionIndexes)
          @dbListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/dblist", atomically: true)
        when 2
          @indexedDBListAry.removeObjectsAtArrangedObjectIndexes(@indexedDBListAry.selectionIndexes)
          @indexedDBListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/idxdblist", atomically: true)
        end        
      end
      self.corpusSelectionChanged(nil)    
    })
  end

  
  
  def openSelectedFile(sender)
    case sender.menu.title
    when "File List"
      item = @currentFileListAry.arrangedObjects[@currentFileListAry.selectionIndex]
    when "Add File List"
      item = @filesToAddAry.arrangedObjects[@filesToAddAry.selectionIndex]
    when "Content File List"
      item = @contentListAry.arrangedObjects[@contentListAry.selectionIndex]
    when "Database List"
      item = @dbListAry.arrangedObjects[@dbListAry.selectionIndex]
    when "Indexed Database List"
      item = @dbListAry.arrangedObjects[@dbListAry.selectionIndex]
    end
    case sender.tag
    when 0
      NSApp.delegate.openSelectedFileInFinder(item)
    when 1
      NSApp.delegate.openSelectedFileWithApp(item)
    when 2
      return if File.extname(item['path']).downcase != ".txt" && File.extname(item['path']) != "" && File.extname(item['path']).downcase != ".pdf"
      case File.extname(item['path']).downcase
      when ".pdf"
        NSApp.delegate.openSelectedPDFFileOnCC(item)
      when ".txt", ""
        NSApp.delegate.openSelectedFileOnCC(item)
      end
    end
  end
  
  
  
  def corpusSelectionChanged(sender)
    return if Defaults['mode'] == 2
    @selectedCDAry[Defaults['mode']].removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@selectedCDAry[Defaults['mode']].arrangedObjects.length]))      
    
    newSelection = Array.new
    
    @cdListAry[Defaults['mode']].arrangedObjects.each do |item|
      newSelection << {'name' => item['name'],'path' => item['path']} if item['check'] == true
    end

    newSelection.insert(0,{'name' => "All"}) if newSelection.length > 1

    @selectedCDAry[Defaults['mode']].addObjects(newSelection)
    
    @cdSelection[Defaults['mode']].each do |lr|
      if newSelection.length > 0
        @appInfoObjCtl.content[lr] = 0 
      else
        @appInfoObjCtl.content.removeObjectForKey(lr)   
      end
    end
  end
  
  
  def addExistingDB(sender)
    panel = NSOpenPanel.openPanel
 		panel.setTitle("Select Database File(s) to Add to the table.")
 		panel.setCanChooseDirectories(false)
 		panel.setCanChooseFiles(true)
 		panel.setAllowsMultipleSelection(true)
 		panel.setPrompt("Select")
    extType = sender.tag == 0 ? [:db] : [:idb]
    panel.setAllowedFileTypes(extType)
    panel.setDirectoryURL(NSURL.URLWithString(Defaults['databaseDefaultFolder']))
    panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
      panel.close
      if result == 1
        case sender.tag
        when 0
          if @dbListAry.arrangedObjects.select{|x| x['name'].downcase == File.basename(panel.filename,".*").downcase}.length > 0
            alert = NSAlert.alertWithMessageText("The dabase with the same name is already on the list.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"Please change the name of the database file to add to the list.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| })
            break
          end
          self.addExistingDBProcess(panel.filenames)
        when 1
          if @indexedDBListAry.arrangedObjects.select{|x| x['name'].downcase == File.basename(panel.filename,".*").downcase}.length > 0
            alert = NSAlert.alertWithMessageText("The dabase with the same name is already on the list.",
                                                defaultButton:"OK",
                                                alternateButton:nil,
                                                otherButton:nil,
                                                informativeTextWithFormat:"Please change the name of the database file to add to the list.")

            alert.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |returnCode| })
            break
          end
          self.addExistingIndexedDBProcess(panel.filenames)
        end
      end
    })
  end
    
  
  
  def addExistingDBProcess(filesAry)
    databaseFiles = Array.new
    @fileContentProgressCircle.startAnimation(nil)
    Dispatch::Queue.concurrent.async{
      filesAry.each do |dbfile|
        totalTokens = 0
        totalFiles = Hash.new
        db = FMDatabase.databaseWithPath(dbfile)
        db.open
        	db.beginTransaction
            if !db.columnExists("encoding",inTableWithName:"conc_data")
              db.executeUpdate("ALTER TABLE conc_data ADD COLUMN encoding integer DEFAULT 0")
            end
            results = db.executeQuery("SELECT path,tokens FROM conc_data")
            while results.next
              totalTokens += results.resultDictionary['tokens'].to_i
              totalFiles[results.resultDictionary['path']] = 1
            end
            databaseFiles << {'name' => File.basename(dbfile,".*"), 'check' => false, 'path' => dbfile, 'files' => totalFiles.length, 'tokens' => totalTokens}
          db.commit
        db.close
      end
      Dispatch::Queue.main.async{
        @dbListAry.addObjects(databaseFiles)
        @fileContentProgressCircle.stopAnimation(nil)
      }
    }
  end
  
  
  def addExistingIndexedDBProcess(filesAry)
    databaseFiles = Array.new
    @fileContentProgressCircle.startAnimation(nil)
    filesAry.each do |dbfile|
      totalTokens = 0
      totalFiles = 0
      db = FMDatabase.databaseWithPath(dbfile)
      db.open
      	db.beginTransaction
          results = db.executeQuery("SELECT file_id,tokens FROM full_text_data")
          while results.next
            totalTokens += results.resultDictionary['tokens'].to_i
            totalFiles += 1
          end
          databaseFiles << {'name' => File.basename(dbfile,".*"), 'check' => false, 'path' => dbfile, 'files' => totalFiles, 'tokens' => totalTokens}
        db.commit
      db.close
    end
    @indexedDBListAry.addObjects(databaseFiles)
    @fileContentProgressCircle.stopAnimation(nil)
  end
  
  
  
	def refreshPreview(sender)
    if sender.state == 0
      @filePreview[sender.tag].setString("")
    else
      case sender.tag
      when 0
        return if Defaults['filePreviewCheck'] != true
        if @currentFileListAry.selectedObjects.length == 0
          @filePreviewText.setString("")
          return
        end
        tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
        contentText = self.readFileContents(@currentFileListAry.arrangedObjects[@currentFileListAry.selectionIndex]['path'],@currentFileListAry.arrangedObjects[@currentFileListAry.selectionIndex]['encoding'],"display",tagsettings,nil)
        @filePreviewText.setString(contentText)
      when 1
        if @filesToAddAry.selectedObjects.length == 0 
          @advFilePreviewText.setString("")
          return
        end
        tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
        contentText = self.readFileContents(@filesToAddAry.arrangedObjects[@filesToAddAry.selectionIndex][0]['path'],@filesToAddAry.arrangedObjects[@filesToAddAry.selectionIndex]['encoding'],"display",tagsettings,nil)
        @advFilePreviewText.setString(contentText)
      when 2
        if @contentListAry.selectedObjects.length == 0 
          @advFilePreviewText.setString("")
          return
        end

        case Defaults['mode']
        when 0
          tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
          contentText = self.readFileContents(@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['path'],@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['encoding'],"display",tagsettings,nil)
        when 1
          fileID = @contentListAry.arrangedObjects[@contentListAry.selectionIndex]['fileID']
          contentText = ""
          
          db = FMDatabase.databaseWithPath(@dbListAry.arrangedObjects[@dbListAry.selectionIndex]['path'])
          db.open
            results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",fileID)
            while results.next
              contentText += results.resultDictionary['text'] + "\n\n"
            end
            results.close
          db.close
        end
        @advFilePreviewText.setString(contentText)
      end
    end
  end
  
  
  def refreshFileListTable(sender)
    case Defaults['mode']
    when 0
      if !Defaults['cdFileListPreviewCheck']
        @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))        
      else
        if @corpusListAry.selectedObjects.length == 0
          @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))        
          return
        end
        @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))
        currentCorpus = @corpusListAry.arrangedObjects[@corpusListAry.selectionIndex]
        corpusFileList = NSArray.arrayWithContentsOfFile(currentCorpus['path'])
        @contentListAry.addObjects(corpusFileList)
      end      
    when 1
      if !Defaults['cdFileListPreviewCheck']
        @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))        
      else
        if @dbListAry.selectedObjects.length == 0
          @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))        
          return
        end
        fileList = Array.new
        db = FMDatabase.databaseWithPath(@dbListAry.arrangedObjects[@dbListAry.selectionIndex]['path'])
        db.open
          results = db.executeQuery("SELECT DISTINCT path,encoding,file_id FROM conc_data")
          while results.next
            lineItem = results.resultDictionary
            fileList << {'path' => lineItem['path'], 'filename' => File.basename(lineItem['path']), 'directory' => File.dirname(lineItem['path']), 'encoding' => lineItem['encoding'].to_i, 'fileID' => lineItem['file_id']}
          end
          results.close
        db.close
        @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))
        @contentListAry.addObjects(fileList)
      end
    end
  end
  
  
  
  def tableViewSelectionDidChange(notification)
    case notification.object
    when @fileTable
      return if Defaults['filePreviewCheck'] != true
      if @currentFileListAry.selectedObjects.length == 0
        @filePreviewText.setString("")
        return
      end
      tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
      contentText = self.readFileContents(@currentFileListAry.arrangedObjects[@currentFileListAry.selectionIndex]['path'],@currentFileListAry.arrangedObjects[@currentFileListAry.selectionIndex]['encoding'],"display",tagsettings,nil)
      @filePreviewText.setString(contentText)
    when @filesToAddTable
      return if Defaults['filePreviewCheck'] != true
      if @filesToAddAry.selectedObjects.length == 0 
        @advFilePreviewText.setString("")
        return
      end
      tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
      contentText = self.readFileContents(@filesToAddAry.arrangedObjects[@filesToAddAry.selectionIndex]['path'],@filesToAddAry.arrangedObjects[@filesToAddAry.selectionIndex]['encoding'],"display",tagsettings,nil)
      @advFilePreviewText.setString(contentText)
    when @cdContentsTable
      return if !Defaults['cdFilePreviewCheck']
      if @contentListAry.selectedObjects.length == 0 
        @advFilePreviewText.setString("")
        return
      end
      case Defaults['mode']
      when 0
        if NSFileManager.defaultManager.fileExistsAtPath(@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['path']) == false
          NSApp.delegate.fileNotFoundWarning(@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['path'])
          return
        else
          tagsettings = Defaults['applyTagsToPreview'] ? self.tagPreparation : []
          contentText = self.readFileContents(@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['path'],@contentListAry.arrangedObjects[@contentListAry.selectionIndex]['encoding'],"display",tagsettings,nil)
        end
      when 1
        fileID = @contentListAry.arrangedObjects[@contentListAry.selectionIndex]['fileID']
        contentText = ""
        db = FMDatabase.databaseWithPath(@dbListAry.arrangedObjects[@dbListAry.selectionIndex]['path'])
        db.open
          results = db.executeQuery("select text, id from conc_data where file_id == ? order by id",fileID)
          while results.next
            contentText += results.resultDictionary['text'] + "\n\n"
          end
          results.close
        db.close
      end
      @advFilePreviewText.setString(contentText)
    when @corporaListTable,@databaseListTable
      self.refreshFileListTable(nil)
    end
  end
  
  
  
  def importCorporaList(sender)
    panel = NSOpenPanel.openPanel
    panel.setAllowsMultipleSelection(true)
    panel.setCanChooseFiles(true)
    panel.setCanChooseDirectories(true)
    panel.setAllowedFileTypes([:ccclist])
    panel.setMessage(NSLocalizedString("Select a corpora list file"))
    panel.beginSheetModalForWindow(@mainWindow,completionHandler:Proc.new { |result|
      panel.close
      if result == 1
        corporaListText = NSMutableString.alloc.initWithContentsOfFile(panel.filename,encoding:TextEncoding[0],error:nil)
        corporaListText.scan(/<corpus>.+?<\/corpus>/m) do |corpus|
          corpus.match(/<corpusData>(.+?)<\/corpusData>/)
          data = $1.split("\t")
          corpusName = data[2].gsub("_"," ")
          fileNum = data[1].to_i
          corpus.match(/<files>(.+?)<\/files>/m)
          fileList = $1.strip.split("\n").map{|x| x.split("\t")}.map{|x| {'path' => x[2], 'filename' => x[1], 'directory' => File.dirname(x[2]), 'encoding' => x[4].to_i}}
          @corpusListAry.addObject({'name' => corpusName,'files' => fileNum, 'check' => false, 'path' => "#{CorpusFolderPath}/#{corpusName}"})
          fileList.map{|x| x.merge({"corpus" => corpusName})}.writeToFile("#{CorpusFolderPath}/#{corpusName}", atomically: true)
        end
        @corpusListAry.arrangedObjects.writeToFile("#{CDListFolderPath}/corpuslist", atomically: true)
      end
    })    
  end
  
  
  
  
  def tagApplication(origString,tagSettings,source,path)
    if Defaults['tagModeEnabled'] && !tagSettings[0].nil?
      if Defaults['ignoreFileHeaderCheck']
        if source == "concord" || source == "display"
          origString.sub!(tagSettings[0]){
            infoSecLength = $&.length #$`.length + $&.length
            NSApp.delegate.appInfoObjCtl.content['concInfoSecLength'][path] = infoSecLength if source == "concord" && Defaults['scopeOfContextChoice'] == 1 && Defaults['concPlotCheck']
            " " * infoSecLength
          }
        else
          origString.sub!(tagSettings[0],"")
        end
      end
      if Defaults['sectionTagHandlingCheck'] && !tagSettings[3].nil?
        if source == "concord" || source == "display"
          origString.gsub!(tagSettings[3]){|x| " " * $&.length}
        else
          origString.gsub!(tagSettings[3],"")
        end
      end
      if Defaults['contextTagsToIgnoreCheck'] && !tagSettings[1].nil?
        if source == "concord" || source == "display"
          origString.gsub!(tagSettings[1]){|x| " " * $&.length}
        else
          origString.gsub!(tagSettings[1],"")
        end
      end
      if Defaults['tagsToIgnoreCheck'] && !tagSettings[2].nil?
        if source == "concord" || source == "display"
          origString.gsub!(tagSettings[2]){|x| $1 + " " * $2.length}
        else
          origString.gsub!(tagSettings[2],"")
        end
      end
      if Defaults['ignoreStringsCheck']
        if source == "concord" || source == "display"
          tagSettings[4].each do |reg|
            next if reg.nil?
            origString.gsub!(reg){|x| " " * $&.length}
          end
        else
          tagSettings[4].each do |reg|
            next if reg.nil?
            origString.gsub!(reg,"")
          end
        end
      end
    end
    return origString   
  end
  
  
  
  
  
  def tagPreparation
    if Defaults['ignoreFileHeaderCheck'] && Defaults['endOfHeaderTag'] != ""
      endOfHeaderTag = Regexp.new("\\A.+(?:#{Regexp.escape(Defaults['endOfHeaderTag'])})",Regexp::IGNORECASE|Regexp::MULTILINE)
    end
    if Defaults['contextTagsToIgnoreCheck']
      case Defaults['contextTagsToIgnoreType']
      when 0
        if Defaults['contextSpecificTags'].strip != ""
          specificTags = Defaults['contextSpecificTags'] == "**" ? ['[^>]+'] : Defaults['contextSpecificTags'].strip.split(",")            
          if Defaults['contextSpecificTagsExcludeCheck']
            contextTagsToIgnore = Regexp.new("</?(?!(?:#{specificTags.join("|")})>)[\\w\\ \\-]+?>",Regexp::IGNORECASE)
          else
            contextTagsToIgnore = Regexp.new("</?(?:#{specificTags.join("|")})>",Regexp::IGNORECASE)
          end
        else
          contextTagsToIgnore = Regexp.new("</?[\\w\\ \\-]+?>",Regexp::IGNORECASE)
        end
      when 1
        if Defaults['contextSpecificTagsCheck'] && Defaults['contextSpecificTags'].strip != ""
          specificTags = Defaults['contextSpecificTags'].strip.split(",")            
          if Defaults['contextSpecificTagsExcludeCheck']
            contextTagsToIgnore = Regexp.new("</?(?:(?!#{specificTags.join("|")})>)|.+?>",Regexp::IGNORECASE)
          else
            contextTagsToIgnore = Regexp.new("</?(?:#{specificTags.join("|")})>",Regexp::IGNORECASE)
          end
        else
          contextTagsToIgnore = Regexp.new("</?.+?>",Regexp::IGNORECASE)
        end
      end
    end
    if Defaults['tagsToIgnoreCheck']
      if Defaults['specificTagsCheck'] && Defaults['specificTags'].strip != ""
        specificPOSTags = Defaults['specificTags'].strip.split(",")
        if Defaults['specificTagsExcludeCheck']
          case Defaults['tagsToIgnoreType']
          when 0
            posTagsToIgnore = Regexp.new("(\\w+)(_(?!(?:#{specificPOSTags.join("|")})[\\b\\B])(?:[A-Za-zÀ-ÿ]\\w*(?:\\b|\\$\\B)))",Regexp::IGNORECASE)
          when 1
            posTagsToIgnore = Regexp.new("(\\w+)(\/(?!(?:#{specificPOSTags.join("|")})[\\b\\B])(?:[A-Za-zÀ-ÿ]\\w*(?:\\b|\\$\\B)))",Regexp::IGNORECASE)
          end
        else
          case Defaults['tagsToIgnoreType']
          when 0
            posTagsToIgnore = Regexp.new("(\\w+)(_(?:#{specificPOSTags.join("|")})[\\b\\B]))",Regexp::IGNORECASE)
          when 1
            posTagsToIgnore = Regexp.new("(\\w+)(\/(?:#{specificPOSTags.join("|")})[\\b\\B]))",Regexp::IGNORECASE)
          end
        end
      else
        case Defaults['tagsToIgnoreType']
        when 0
          posTagsToIgnore = Regexp.new("(\\w+)(_(?:[A-Za-zÀ-ÿ]\\w*(?:\\b|\\$\\B)))",Regexp::IGNORECASE)
        when 1
          posTagsToIgnore = Regexp.new("(\\w+)(\/(?:[A-Za-zÀ-ÿ]\\w*(?:\\b|\\$\\B)))",Regexp::IGNORECASE)
        end
      end
    end
    if Defaults['sectionTagHandlingCheck']
      sectionTagsAry = Array.new
      Defaults['sectionTagsAry'].each do |item|
        next if not item['check']
        sectionTagsAry << item['tag']
      end
      sectionTags = /<(#{sectionTagsAry.join("|")})>.+?<\/\1>/mi

      #sectionTags = Regexp.new("<(#{sectionTagsAry.join("|")})>.+?<\/#{sectionTagsAry.join("|")}>",Regexp::IGNORECASE|Regexp::MULTILINE)
    end
    if Defaults['ignoreStringsCheck']
      stringsToIgnore = Array.new
      Defaults['ignoreStringsAry'].each do |item|
        next if not item['check']
        if item['case'] && item['ml']
          stringsToIgnore << Regexp.new(item['reg'],Regexp::MULTILINE)
        elsif item['case']
          stringsToIgnore << Regexp.new(item['reg'])        
        elsif item['ml']
          stringsToIgnore << Regexp.new(item['reg'],Regexp::IGNORECASE|Regexp::MULTILINE)        
        else
          stringsToIgnore << Regexp.new(item['reg'],Regexp::IGNORECASE)
        end
      end      
    end
    return [endOfHeaderTag,contextTagsToIgnore,posTagsToIgnore,sectionTags,stringsToIgnore]
  end
  
  
  
  def numberOfRowsInTableView(tableView)
    case tableView
    when @fileTable
      @currentFileListAry.arrangedObjects.length
    when @filesToAddTable
      @filesToAddAry.arrangedObjects.length
    when @cdContentsTable
      @contentListAry.arrangedObjects.length
    end
	end

		
	def tableView(tableView,objectValueForTableColumn:col,row:row)
    case col
    when tableView.tableColumnWithIdentifier('id')
      row + 1
    end
	end
  
  
  def tableView(table, validateDrop: info, proposedRow: row, proposedDropOperation: operation)
    if operation == 1 && info.draggingPasteboard.types.include?("NSFilenamesPboardType")
	    return NSDragOperationCopy
    elsif operation == 1
	    return NSDragOperationEvery     
    else
      return NSDragOperationNone
    end
  end
  
  
  def tableView(table, acceptDrop: info, row: row, dropOperation: operation)
    pasteBoard = info.draggingPasteboard
    case table
    when @currentFileListTable,@filesToAddTable
      data = pasteBoard.propertyListForType(NSFilenamesPboardType)
      filesToAdd = self.addFilesToList(data,"drag")
      @fileAry[Defaults['corpusMode']].insertObjects(filesToAdd, atArrangedObjectIndexes: NSIndexSet.indexSetWithIndexesInRange([row,filesToAdd.length]))
      return true     
    when @corporaListTable,@databaseListTable,@indexedDatabaseListTable
      if info.draggingPasteboard.types.include?(NSFilenamesPboardType)
        case table
        when @corporaListTable
          return false
        when @databaseListTable
          return false if (data = pasteBoard.propertyListForType(NSFilenamesPboardType).select{|x| File.extname(x).downcase == ".db"}).length == 0
          self.addExistingDBProcess(data)
          return true
        when @indexedDatabaseListTable
          return false if (data = pasteBoard.propertyListForType(NSFilenamesPboardType).select{|x| File.extname(x).downcase == ".idb"}).length == 0
          self.addExistingIndexedDBProcess(data)
          return true
        end
      else
        movingItems = pasteBoard.propertyListForType(TableContentType)
        idx = @movingIndexes.mutableCopy
        lidx = 0
        while idx.count > 0
          break if idx.firstIndex >= row
          lidx += 1
          idx.removeIndex(idx.firstIndex)
        end
        insertRow = row - lidx      
        @cdListAry[Defaults['mode']].removeObjectsAtArrangedObjectIndexes(@movingIndexes)
    		@cdListAry[Defaults['mode']].insertObjects(movingItems,atArrangedObjectIndexes:NSIndexSet.indexSetWithIndexesInRange([insertRow,movingItems.length]))		    
        @cdListAry[Defaults['mode']].arrangedObjects.writeToFile(@cdListPath[Defaults['mode']], atomically: true)
        self.corpusSelectionChanged(nil)
        return true                
      end
    end
	end
  
  
  def tableView(table, writeRowsWithIndexes: idx, toPasteboard: pasteboard)
    case table
    when @corporaListTable,@databaseListTable
      @movingIndexes = idx
      movingObjects = @cdListAry[Defaults['mode']].arrangedObjects.objectsAtIndexes(idx)
      pasteboard.declareTypes([TableContentType], owner: self)
      pasteboard.setPropertyList(movingObjects,forType:TableContentType)
      return true
    end
  end


  def checkAllItems(sender)
    case sender.tag
    when 0
      if sender.state == NSOffState
        @corpusListAry.arrangedObjects.each do |item|
          item['check'] = false
        end
      else
        @corpusListAry.arrangedObjects.each do |item|
          item['check'] = true
        end
      end
    when 1
      if sender.state == NSOffState
        @dbListAry.arrangedObjects.each do |item|
          item['check'] = false
        end
      else
        @dbListAry.arrangedObjects.each do |item|
          item['check'] = true
        end
      end
    end
    self.corpusSelectionChanged(nil)
  end


  def selectIndexDB(sender)
    rowIdx = @indexedDatabaseListTable.clickedRow
    if @indexedDBListAry.arrangedObjects[rowIdx]['check'] == true
      @indexedDBListAry.arrangedObjects.each_with_index do |item,idx|
        next if idx == rowIdx
        item['check'] = false
      end
    end
  end
  

  def tabView(tabView, didSelectTabViewItem: tabViewItem)
    @contentListAry.removeObjectsAtArrangedObjectIndexes(NSIndexSet.indexSetWithIndexesInRange([0,@contentListAry.arrangedObjects.length]))
  end
  
  
end