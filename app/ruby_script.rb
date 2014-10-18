module Kernel
  private

  def NSLocalizedString(string)
    return NSBundle.mainBundle.localizedStringForKey(string, value:string, table:nil)
  end
end

class MyString < String
  
  def init(inText)
    return inText.nil? ? "" : inText.dup
  end
  
  def concRegConversion(wwd,source)

    return nil if self == ""
    
    case Defaults['searchWordMode']
  	when 0
      keyword = self.dup

      if (keyword == "\\w" || keyword == "!") && source[0] == "wc"
        keyword = "\\w"
      else

        wwd = WildWordProcess.new("conc") if wwd.nil?
      
      
        if Defaults['kwgCheck'] && NSApp.delegate.kwGroups != nil
          keyword.gsub!(/@@(\w+)/){|x| "(?:#{NSApp.delegate.kwGroups[$1]})"}
        end
        if (Defaults['lemmaCheck'] && NSApp.delegate.lemmas != nil) && (Defaults['spVarCheck'] && NSApp.delegate.spellVars != nil)
          keyword.gsub!(/#{wwd.wordBase}/){|x| 
          allItems = []
          NSApp.delegate.spellVars[NSApp.delegate.lemmaInclude[x.downcase]].split("|").each do |word|
            NSApp.delegate.lemmas[word.downcase].split("|").each do |lms|
              allItems << NSApp.delegate.spellVars[NSApp.delegate.spellVarInclude[lms.downcase]]
            end
          end
          "(?:#{allItems.flatten.uniq.sort_by{|y| -y.length}.join("|")})"
          }
        elsif Defaults['lemmaCheck'] && NSApp.delegate.lemmas != nil
          keyword.gsub!(/#{wwd.wordBase}/){|x| "(?:#{NSApp.delegate.lemmas[NSApp.delegate.lemmaInclude[x.downcase]]})"}
        elsif Defaults['spVarCheck'] && NSApp.delegate.spellVars != nil
          keyword.gsub!(/#{wwd.wordBase}/){|x| "(?:#{NSApp.delegate.spellVars[NSApp.delegate.spellVarInclude[x.downcase]]})"}
        end
      
            
        if /\// =~ keyword
        	keyword.gsub!(/ *\/ */,"|")
        end
        keyword.gsub!(/\(([\*\?])\)/){|x| $1}
        keyword.gsub!(/\?\:/,"√∛∛∛√")
        keyword.gsub!(/\?\!/,"√∛∛∜√")
      
        keyword.gsub!(/\*\*/,"√∛∛∛∛∛√")
        keyword.gsub!(/\?\?/,"√∛∛∛∛∜√")
        keyword.gsub!(/\!\!/,"√∛∛∛∜∛√")
        keyword.gsub!(/\$\$/,"√∛∛∛∜∜√")


        keyword = keyword.split("/").map{|y|
          y.gsub(/\*/){|x|
            lt = $`
            rt = $'
            if lt.match(/\w$|\w\)$/) && rt.match(/^\w|^\((?:√∛∛∛√)?\w/)
              "√∜∛∛∛∛√"
            elsif lt.match(/\w$|\w\)$/)
              "√∜∛∛∛∜√"
            elsif rt.match(/^\w|^\((?:√∛∛∛√)?\w/)
              "√∜∛∛∜∛√"            
            elsif (lt.match(/[^\ \w\(]$/) || lt == "") && rt.match(/\ [^\*\?]/)
              "√∜∛∛∜∜√"
            elsif (lt.match(/[^\ \w\(]$/) || lt == "")
              "√∜∛∜∛∛√"
            else
              "√∜∛∜∛∜√"
            end
          }.gsub(/\?/){|x|
            lt = $`
            rt = $'
            if lt.match(/\w$|\w\)$/) || rt.match(/^\w|^\((?:√∛∛∛√)?\w/)
              "√∜∛∜∜∛√"
            elsif lt.match(/\w$|\w\)$/)
              "√∜∛∜∜∜√"
            elsif rt.match(/^\w|^\((?:√∛∛∛√)?\w/)
              "√∜∜∛∛∛√"
            else
              "√∜∜∛∛∜√"
            end
          }.gsub(/\!/,"√∜∜∛∜∛√")
        }.join("|")

        keyword.gsub!(/\./,'\.')

        keyword.gsub!(/√∛∛∛∛∛√/,'\*')
        keyword.gsub!(/√∛∛∛∛∜√/,'\?')
        keyword.gsub!(/√∛∛∛∜∛√/,'\!')
        keyword.gsub!(/√∛∛∛∜∜√/,'\$')
        keyword.gsub!(/√∜∛∛∛∛√/,"(?:#{wwd.midWordBase})?")
        keyword.gsub!(/√∜∛∛∛∜√/,"(?:#{wwd.tailWordBase})?")
        keyword.gsub!(/√∜∛∛∜∛√/,"(?:#{wwd.initWordBase})?")
        keyword.gsub!(/√∜∛∛∜∜√\ /,"(?:#{wwd.wildWord}\ )?")
        keyword.gsub!(/√∜∛∜∛∛√/,"(?:#{wwd.wildWord})?")
        keyword.gsub!(/\ √∜∛∜∛∜√/,"(?:\ #{wwd.wildWord})?")
        keyword.gsub!(/√∜∛∜∛∜√/,"(?:#{wwd.wildWord})?")
        keyword.gsub!(/√∜∛∜∜∛√/,"(?:#{wwd.midWordBase})")
        keyword.gsub!(/√∜∛∜∜∜√/,"(?:#{wwd.tailWordBase})")
        keyword.gsub!(/√∜∜∛∛∛√/,"(?:#{wwd.initWordBase})")
        keyword.gsub!(/√∜∜∛∛∜√/,"(?:#{wwd.wildWord})")
        keyword.gsub!(/√∜∜∛∜∛√/,wwd.wildChar)
        keyword.gsub!(/√∛∛∛√/,"?:")
        keyword.gsub!(/√∛∛∜√/,"?!")
      end
  		begin
  		  #if source[0] == "wc" || !Defaults['searchWordCaseSensitivity']
    		if !Defaults['searchWordCaseSensitivity']
		      caseSensitivity = Regexp::IGNORECASE
  		  else
  		    caseSensitivity = 0
  	    end
        if (keyword == "\\w" || keyword == "!") && source[0] == "wc"
          regText = "\\w"
        else
          if self.split("/").select{|x| x.match(/^(?:\(\?\:)*[\w\?\!\*]/) && x.match(/[\w\?\!\*]\)*$/)}.length > 0
            regText = "\\b(?:#{keyword})\\b"
          elsif self.split("/").select{|x| x.match(/^(?:(?:\(\?\:)*[\w\?\!\*])/) && x.match(/[\w\?\!\*]\)*$/).nil?}.length > 0
            regText = "\\b(?:#{keyword})(?:\\B|\\b|$)"
          elsif self.split("/").select{|x| x.match(/^(?:(?:\(\?\:)*[\w\?\!\*])/).nil? && x.match(/[\w\?\!\*]\)*$/)}.length > 0
            regText = "(?:^|\\B|\\b)(?:#{keyword})\\b"
          else
            regText = "(?:^|\\B|\\b)(?:#{keyword})(?:\\B|\\b|$)"
          end
        end
        if Defaults['searchInBWNonAlph'] || source[0] == "wc" && NSApp.delegate.appInfoObjCtl.content["wcBWNonCharCheck#{source[1]}"]
          regText.gsub!(/\ /,'[^\w\f\r\n]+')
        else
          #regText.gsub!(/\ /,'\ +')
        end
        reg = Regexp.new(regText,caseSensitivity)
      rescue
        p "Regular Expression Error Occurred"
        return Regexp.new("/Regular Expression Error Occurred/")
      end
  	when 1
  		begin
    	  if Defaults['searchWordCaseSensitivity']
    		  reg = Regexp.new(Regexp.escape(self))
  		  else
    		  reg = Regexp.new(Regexp.escape(self),Regexp::IGNORECASE)
  	    end
      rescue
        p "Regular Expression Error Occurred"
        return Regexp.new("/Regular Expression Error Occurred/")
      end
  	when 2
  		begin
    	  if Defaults['searchWordCaseSensitivity'] && Defaults['searchWordMultiLine'] != true
      		reg = Regexp.new(self)
      	elsif Defaults['searchWordCaseSensitivity'] != true && Defaults['searchWordMultiLine']
  	      reg = Regexp.new(self,Regexp::IGNORECASE|Regexp::MULTILINE)
        elsif Defaults['searchWordCaseSensitivity'] != true && Defaults['searchWordMultiLine'] != true
  	      reg = Regexp.new(self,Regexp::IGNORECASE)
  	    elsif Defaults['searchWordCaseSensitivity'] && Defaults['searchWordMultiLine']
  	      reg = Regexp.new(self,Regexp::MULTILINE)
        end
        p reg
      rescue
        p "Regular Expression Error Occurred"
        return Regexp.new("/Regular Expression Error Occurred/")
      end
  	end
  	
  	return reg
  end
  
  def toSql
    keyword = self
    case
    when 0
      keyword = self
      if keyword.match(/\w/)
        begin
          searchWords = []
          searchWords2 = []
          searchWords3 = []

          keyword.gsub!(/\?\:/,"")

          searchWordsTemp = keyword.split(/\//)

          keyword.split(/\//).sort_by{|x| x.length}.each do |stem|
            searchWordsTemp.delete_if{|a| Regexp.new(Regexp.escape(stem)+"\\w+") =~ a }
          end


          searchWordsTemp.each do | searchWord |

            searchWord.gsub!(/([\ \|\/])[\!\*\?]+([\ \|\/])/,'\1AND\2')
            searchWord.gsub!(/[\!\*\?]+/," AND")
            searchWord.gsub!(/？/,"")

            #searchWords = Defaults['includeNonAlphCharCheck'].to_i == 1 ? searchWord.split(/[\/\ ]+/) : searchWord.split(/\//)

            searchWord.strip!
            searchWord.gsub!(/\'/,"''")
            searchWord.gsub!(/\(/, "AND ( text like '%")
            searchWord.gsub!(/\|/, "%' OR text like '%")
            searchWord.gsub!(/\)/, "%' ) AND ")
            sw_out = "( "
            searchWord.split(/ *AND */).delete_if{|x| x == ""}.each do | sw |
              sw_out << "text like '%"+sw+"%' AND "
            end
            next if sw_out == "( "
            sw_out.gsub!(/text like \'\%\(/,"( ")
            sw_out.gsub!(/\)%\'/," )")
            sw_out.gsub!(/ AND *$/,"")
            sw_out << " ) "
            searchWords3 << sw_out

          end
          search_string = "WHERE " + searchWords3.join(" OR ").gsub(/\ +/," ")
        rescue
          p "Regular Expression Error Occurred in SQL Process"
          search_string = ""
        end
      else
        search_string = ""
      end
    when 1
      if keyWord =~ /[%_]/
  		  sql = "WHERE text LIKE '%#{keyWord.gsub(/[$%_]/){|s| "$"+s}}%' ESCAPE '$' "
      else
  		  sql = "WHERE text LIKE '%#{keyWord}%'"
      end
    when 2
      search_string = ""
    end
    return search_string
  end
  
end


class WildWordProcess
  extend IB
  attr_accessor :wildChar,:wordBase,:baseWord,:wildWord,:initWordBase,:tailWordBase,:midWordBase
  
  def initialize(source)
    if Defaults['wchSkipCharCheck'] && NSApp.delegate.skipChars != nil
      wildChar = "(?:(?![#{Regexp.escape(NSApp.delegate.skipChars)}])\\w)"
    else
      wildChar = "\\w" #"(?:\\w)"
    end

    if (source != "conc" || Defaults['applyIncludeCharInConcSearch']) && ((Defaults['qouteIncludeCheck'] || Defaults['hyphenIncludeCheck'] || (Defaults['othersIncludeCheck'] && Defaults['partOfWordChars'] != "")) && NSApp.delegate.includeAsPartWordChars != nil)
      wordBase = "(?:#{wildChar}+(?:[#{NSApp.delegate.includeAsPartWordChars}]#{wildChar}+)*)"
      @initWordBase = "(?:#{wildChar}+(?:[#{NSApp.delegate.includeAsPartWordChars}]#{wildChar}*)*)"
      @tailWordBase = "(?:#{wildChar}*(?:[#{NSApp.delegate.includeAsPartWordChars}]*#{wildChar}+)+)"
      @midWordBase = "(?:#{wildChar}*(?:[#{NSApp.delegate.includeAsPartWordChars}]|#{wildChar})+)"
    else
      wordBase = "#{wildChar}+"
      @initWordBase = "#{wildChar}+"
      @tailWordBase = "#{wildChar}+"
      @midWordBase = "#{wildChar}+"
    end
    
    if source != "conc" || source != "plot"
      if Defaults['wchStopWordCheck'] && NSApp.delegate.stopWords != nil
        baseWord = "(?!\b(?:#{NSApp.delegate.stopWords})\b)#{wordBase}"
      else
        baseWord = wordBase
      end
    else
      baseWord = wordBase
    end

    if Defaults['wchMultiWordCheck'] && NSApp.delegate.multiWords != nil
      if Defaults['wchIncludeWordCheck'] && NSApp.delegate.includeWords != nil
        if NSApp.delegate.includeWords[0] != nil && NSApp.delegate.includeWords[1] != nil
          wildWord = "\\b(?:(?:#{NSApp.delegate.includeWords[0]})\\B|(?:#{NSApp.delegate.multiWords}|#{NSApp.delegate.includeWords[1]}|#{baseWord})\\b)"
        elsif NSApp.delegate.includeWords[1].nil? && NSApp.delegate.includeWords[0] != nil
          wildWord = "\\b(?:(?:#{NSApp.delegate.includeWords[0]})\\B|(?:#{NSApp.delegate.multiWords}|#{baseWord})\\b)"
        elsif NSApp.delegate.includeWords[0].nil? && NSApp.delegate.includeWords[1] != nil
          wildWord = "\\b(?:#{NSApp.delegate.multiWords}|#{NSApp.delegate.includeWords[1]}|#{baseWord})\\b"
        else
          wildWord = "\\b(?:#{baseWord})\\b"
        end
      else
        wildWord = "\\b(?:#{baseWord})\\b"
      end
    else
      if Defaults['wchIncludeWordCheck'] && NSApp.delegate.includeWords != nil      
        if NSApp.delegate.includeWords[0] != nil && NSApp.delegate.includeWords[1] != nil
          wildWord = "\\b(?:(?:#{NSApp.delegate.includeWords[0]})\\B|(?:#{NSApp.delegate.includeWords[1]}|#{baseWord})\\b)"
        elsif NSApp.delegate.includeWords[1].nil? && NSApp.delegate.includeWords[0] != nil
          wildWord = "\\b(?:(?:#{NSApp.delegate.includeWords[0]})\\B|#{baseWord}\\b)"
        elsif NSApp.delegate.includeWords[0].nil? && NSApp.delegate.includeWords[1] != nil
          wildWord = "\\b(?:#{NSApp.delegate.includeWords[1]}|#{baseWord})\\b"
        else
          wildWord = "\\b(?:#{baseWord})\\b"
        end
      else
        wildWord = "\\b(?:#{baseWord})\\b"
      end
    end
    wildWord += "|\\B#\\B" if source == "wc" && Defaults['numberHandleChoice'] == 1
    @wildChar = wildChar
    @wordBase = wordBase
    @baseWord = baseWord
    @wildWord = wildWord
    return "true"
  end
    
end