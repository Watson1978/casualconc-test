TextEncoding = [NSUTF8StringEncoding,NSUnicodeStringEncoding,NSWindowsCP1252StringEncoding,NSWindowsCP1250StringEncoding,NSMacOSRomanStringEncoding,NSASCIIStringEncoding,NSShiftJISStringEncoding,NSJapaneseEUCStringEncoding,NSISO2022JPStringEncoding,NSISOLatin1StringEncoding,NSISOLatin2StringEncoding]
EncodingConverter = {"0" => 0, "1" => 0, "2" => 4, "3" => 5, "4" => 0, "5" => 1, "6" => 0, "7" => 0, "8" => 0, "9" => 2, "10" => 3}
Defaults = NSUserDefaults.standardUserDefaults
ConcSpanValues = [0,10,20,30,40,50,60,70,80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,230,240,250]
ConcFont = ["Courier","Courier New"]
CCFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc"
CorpusFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc/corpus"
CDListFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc/cdlists"
WCHFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc/wchandler"
LKSListFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc/lkslist"
TempFolderPath = "#{NSHomeDirectory()}/Library/Application Support/CasualConc/temp"
ResourcesFolderPath = "#{NSBundle.mainBundle.bundlePath}/Contents/Resources"
CRCharReg = /[\t\r\n\f]/
CRCharLongReg = /[\r\n\f\t]{1,30}/
CRReg = /\r\n|\n|\r/
AcceptFileTypes = ['ftPlainText','ftRichText','ftHtml','ftWebarchive','ftPdf','ftMsWord','ftOpenOffice','ftXML']
AcceptFileExtensions = [['txt'],['rtf','rtfd'],['htm','html'],['webarchive'],['pdf'],['doc','docx'],['odt','sxw'],['xml']]
AssignedApp = {".doc" => 'appForMsWord',".docx" => 'appForMsWord',".rtf" => 'appForRt',".rtfd" => 'appForRt',".pdf" => 'appForPdf',".html" => 'appForWeb',".htm" => 'appForWeb',".webarchive" => 'appForWeb',".txt" => 'appForPt',".odt" => 'appForOpenOffice',".sxw" => 'appForOpenOffice'}
TableContentType = "TableContentType"
NOC = "<NO_CORPUS>"
SortOrderLabels = {"L10"=>0, "L9"=>1, "L8"=>2, "L7"=>3, "L6"=>4, "L5"=>5, "L4"=>6, "L3"=>7, "L2"=>8, "L1"=>9, "Key"=>10, "R1"=>11, "R2"=>12, "R3"=>13, "R4"=>14, "R5"=>15, "R6"=>16, "R7"=>17, "R8"=>18, "R9"=>19, "R10"=>20, "FN"=>21, "POS"=>22}
SortOrderlabelAry = ["l10", "l9", "l8", "l7", "l6", "l5", "l4", "l3", "l2", "l1", "keyw", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r8", "r9", "r10", "file_name", "key_pos_loc"]