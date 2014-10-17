#
#  ListItemProcesses.rb
#  CasualConc
#
#  Created by Yasu on 10/11/28.
#  Copyright (c) 2010 Yasu Imao. All rights reserved.
#

class ListItemProcesses
  
  def init
  end

  def stopWordPrepare
    if Defaults['wcHandlerGroupList'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/stopText") == false
      NSApp.delegate.stopWords = nil
      return self
    end
    NSApp.delegate.stopWords = NSString.stringWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/stopText", encoding: TextEncoding[0], error: nil)
    #NSApp.delegate.stopWords = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/stopText")
    return self
  end
  
  def skipCharPrepare
    if Defaults['wcHandlerGroupList'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/skipText") == false
      NSApp.delegate.skipChars = nil
      return self
    end
    NSApp.delegate.skipChars = NSString.stringWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/skipText", encoding: TextEncoding[0], error: nil)
    #NSApp.delegate.skipChars = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/skipText")
    return self
  end
  
  def includeWordPrepare
    if Defaults['wcHandlerGroupList'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/includeText") == false
      NSApp.delegate.includeWords = nil
      return self
    end
    NSString.stringWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/includeText", encoding: TextEncoding[0], error: nil).match(/(.+?)?\n(.+?)?/)
    NSApp.delegate.includeWords = [$1,$2]
    #NSApp.delegate.includeWords = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/includeText")
    return self
  end
  
  def multiWordPrepare
    if Defaults['wcHandlerGroupList'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/multiwordText") == false
      NSApp.delegate.multiWords = nil 
      return self
    end
    NSApp.delegate.multiWords = NSString.stringWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/multiwordText", encoding: TextEncoding[0], error: nil)
    #NSApp.delegate.multiWords = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/multiwordText")
    return self
  end
  
  def lemmaPrepare
    if Defaults['lemmaGroups'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{LKSListFolderPath}/lemma/#{Defaults['lemmaGroups'][Defaults['lemmaGroupChoice']]['group']}/eachitemlist") == false
      NSApp.delegate.lemmas = nil
      NSApp.delegate.lemmaInclude = nil
      return self
    end
    lemmaHash = Hash.new{|hash,key| hash[key] = key}
    lemmaIncludeHash = Hash.new{|hash,key| hash[key] = key}
    lemmaHash.merge!(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/lemma/#{Defaults['lemmaGroups'][Defaults['lemmaGroupChoice']]['group']}/eachitemlist"))
    lemmaIncludeHash.merge!(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/lemma/#{Defaults['lemmaGroups'][Defaults['lemmaGroupChoice']]['group']}/keylist"))
    NSApp.delegate.lemmas = lemmaHash
    NSApp.delegate.lemmaInclude = lemmaIncludeHash
    return self
  end
  
  def lemmaApplication(items,inFiles,source)
    case source
    when "wc"
      newItems = Hash.new(0)
      newInfiles = Hash.new{|x,y| x[y] = {}}
      lemmaList = Hash.new{|x,y| x[y] = []}
      items.each do |item,count|
        ary = Array.new
        #item.split(" ").each do |word|
        item.each do |word|
          ary << NSApp.delegate.lemmaInclude[word]
        end
        newItem = ary#.join(" ")
        newItems[newItem] += count
        newInfiles[newItem].merge!(inFiles[item]) if inFiles != {}
        lemmaList[newItem] << [item,count]
      end
      return [newItems,lemmaList,newInfiles]
    when "col"
      newItems = Hash.new{|hash,key| hash[key] = Hash.new}
      lemmaList = Hash.new{|x,y| x[y] = []}
      if Defaults['collocTreatOneWordCheck']
        items.each do |item,count|
          if newItems[NSApp.delegate.lemmaInclude[item]] == {}
            newItems[NSApp.delegate.lemmaInclude[item]] = count
          else
            newItems[NSApp.delegate.lemmaInclude[item]].merge!(count) {|key,val1,val2| val1 + val2}
          end
          lemmaList[NSApp.delegate.lemmaInclude[item]] << "#{item} (#{count['lrTotal']})"
        end
      else
        items.each do |item,count|
          keys = item.split("__")
          keyword = keys[0]
          contextWord = keys[1]
          if newItems["#{NSApp.delegate.lemmaInclude[keys[0]]}__#{NSApp.delegate.lemmaInclude[keys[1]]}"] == {}
            newItems["#{NSApp.delegate.lemmaInclude[keys[0]]}__#{NSApp.delegate.lemmaInclude[keys[1]]}"] = count
          else
            newItems["#{NSApp.delegate.lemmaInclude[keys[0]]}__#{NSApp.delegate.lemmaInclude[keys[1]]}"].merge!(count) {|key,val1,val2| val1 + val2}
          end
          lemmaList["#{NSApp.delegate.lemmaInclude[keys[0]]}__#{NSApp.delegate.lemmaInclude[keys[1]]}"] << "#{item.sub("__","-")} (#{count['lrTotal']})"
        end
      end
      return [newItems,lemmaList]
    when "clst"
      newItems = Hash.new(0)
      newInfiles = Hash.new{|x,y| x[y] = {}}
      newInCorpus = Hash.new{|x,y| x[y] = {}}
      lemmaList = Hash.new{|x,y| x[y] = []}
      items.each do |item,count|
        ary = Array.new
        item.each do |word|
          ary << NSApp.delegate.lemmaInclude[word]
        end
        newItem = ary#.join(" ")
        newItems[newItem] += count
        newInfiles[newItem].merge!(inFiles[0][item]) if inFiles[0] != {}
        newInCorpus[newItem].merge!(inFiles[1][item]) if inFiles[1] != {}
        lemmaList[newItem] << [item,count]
      end
      return [newItems,lemmaList,newInfiles,newInCorpus]
    end
  end
  
  def kwgPrepare
    if Defaults['kwgGroups'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{LKSListFolderPath}/kwg/#{Defaults['kwgGroups'][Defaults['kwgGroupChoice']]['group']}/eachitemlist") == false
      NSApp.delegate.kwGroups = nil
      return self
    end
    kwgHash = Hash.new{|hash,key| hash[key] = key}
    kwgHash.merge!(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/kwg/#{Defaults['kwgGroups'][Defaults['kwgGroupChoice']]['group']}/eachitemlist"))

    NSApp.delegate.kwGroups = kwgHash
    return self
  end
  
  def spvPrepare
    if Defaults['spVarGroups'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{LKSListFolderPath}/spv/#{Defaults['spVarGroups'][Defaults['spVarGroupChoice']]['group']}/eachitemlist") == false
      NSApp.delegate.spellVars = nil
      NSApp.delegate.spellVarInclude = nil
      return self
    end
    spvHash = Hash.new{|hash,key| hash[key] = key}
    spvIncludeHash = Hash.new{|hash,key| hash[key] = key}
    spvHash.merge!(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/spv/#{Defaults['spVarGroups'][Defaults['spVarGroupChoice']]['group']}/eachitemlist"))
    spvIncludeHash.merge!(NSMutableDictionary.dictionaryWithContentsOfFile("#{LKSListFolderPath}/spv/#{Defaults['spVarGroups'][Defaults['spVarGroupChoice']]['group']}/keylist"))

    NSApp.delegate.spellVars = spvHash
    NSApp.delegate.spellVarInclude = spvIncludeHash
    return self
  end

  def charReplacePrepare
    if Defaults['replaceCharsAry'].length == 0
      NSApp.delegate.relaceChars = nil 
      return self
    end
    replaceCharHash = Hash.new
    replaceCharToProcessText = ""
    Defaults['replaceCharsAry'].each do |item|
      case item['check']
      when false,nil
        replaceCharHash[item['fromChar']] = item['toChar']
        replaceCharToProcessText += Regexp.escape(item['fromChar'])
      when true
        replaceCharHash[item['fromChar']] = item['toChar']          
        replaceCharToProcessText += item['fromChar']
      end
    end
    NSApp.delegate.relaceChars = [Regexp.new('[' + replaceCharToProcessText + ']'),replaceCharHash]
    return self
  end
  
  def includeAsPartWordPrepare
    includeAsPartWordChars = ""
    includeAsPartWordChars += "'" if Defaults['qouteIncludeCheck']
    includeAsPartWordChars += "-" if Defaults['hyphenIncludeCheck']
    includeAsPartWordChars += Defaults['partOfWordChars'] if Defaults['othersIncludeCheck'] && Defaults['partOfWordChars'] != ""
    if includeAsPartWordChars == ""
      NSApp.delegate.includeAsPartWordChars = nil
    else
      NSApp.delegate.includeAsPartWordChars = Regexp.escape(includeAsPartWordChars)
    end
    return self
  end
  
  def eosWordPrepare
    if Defaults['wcHandlerGroupList'].length == 0 || NSFileManager.defaultManager.fileExistsAtPath("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/notEnd") == false
      NSApp.delegate.nonEOSWords = nil
      return self
    end
    NSApp.delegate.nonEOSWords = NSString.stringWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/notEndText", encoding: TextEncoding[0], error: nil)
    #NSApp.delegate.nonEOSWords = NSArray.arrayWithContentsOfFile("#{WCHFolderPath}/#{Defaults['wcHandlerGroupList'][Defaults['wcHandlerGroup']]['group']}/notEnd").map{|x| x['word']}.sort_by{|x| -x.length}.join("|")
    return self
  end
  
  
end
