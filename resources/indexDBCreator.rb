# /usr/bin/ruby

$LOAD_PATH << "[RESOUCES PATH]/Gems/sqlite3-1.3.9/lib"

require 'sqlite3'
require "find"

files = Array.new
File.open([FileListPath],'r') do |f|
  files = f.read.split("\n")
end


stopWords = ['the','a','an','is','are','be','was','were','of','in','and','but','for','to','at']
t = Time.new
sql = <<-SQL
  CREATE table conc_idx_data (
  id integer PRIMARY KEY AUTOINCREMENT,
  file_name text,
  encoding integer,
  key text,
  key2 text,
  key3 text,
  key4 text,
  key5 text,
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
  r6 text,
  r7 text,
  r8 text,
  r9 text,
  keyw text,
  l5_pos_loc integer,
  l5_pos_len integer,
  l4_pos_loc integer,
  l4_pos_len integer,
  l3_pos_loc integer,
  l3_pos_len integer,
  l2_pos_loc integer,
  l2_pos_len integer,
  l1_pos_loc integer,
  l1_pos_len integer,
  key_pos_loc integer,
  key_pos_len integer,
  key_local_pos integer,
  key2_pos_len integer,
  key3_pos_len integer,
  key4_pos_len integer,
  key5_pos_len integer,
  r1_pos_loc integer,
  r1_pos_len integer,
  r2_pos_loc integer,
  r2_pos_len integer,
  r3_pos_loc integer,
  r3_pos_len integer,
  r4_pos_loc integer,
  r4_pos_len integer,
  r5_pos_loc integer,
  r5_pos_len integer,
  r6_pos_loc integer,
  r6_pos_len integer,
  r7_pos_loc integer,
  r7_pos_len integer,
  r8_pos_loc integer,
  r8_pos_len integer,
  r9_pos_loc integer,
  r9_pos_len integer,
  path text,
  file_id integer
  );
SQL

    sql2 = <<-SQL
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

#=end
db = SQLite3::Database.new([DBFileName])
reg1 = /\b(\w+(?:\'\w+)?)\b/
reg2 = /\A\b(?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?)\b/
reg3 = /\A\b(?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?)\b/
reg4 = /\A\b(?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?)\b/
reg5 = /\A\b(?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?) (?:\w+(?:\'\w+)?)\b/

db.execute(sql)
db.execute(sql2)

reg = /\b(?:\w+(?:\'\w+)?)\b/
inforeg = /<info>.+?<\/info>\n?/mi
tagreg = /<\/?\w+>/
sreg = /\s+/
idx = 0
totalTokens = 0
files.each do |file|
  db.transaction do
    File.open(file,'r') do |f|
      text = f.read
      text.gsub!(inforeg,"")
      text.gsub!(tagreg,"")
      fileTokens = text.scan(reg).length
      totalTokens += fileTokens
      db.execute("INSERT INTO full_text_data (id,file_name,text,path,file_id,encoding,tokens) values (null,?,?,?,?,?,?)",File.basename(file),text,file,idx,0,fileTokens)
      text.scan(reg) do |item|
        key = $&
        keyPos = $`.length
        #next if stopWords.include?(key.downcase)
        if $`.length < 80
          leftText = $`
        else
          leftText = $`[-80,80]
        end
        rightText = $'[0,100]
        newText = key + rightText
        key2 = newText.match(reg2).to_s.downcase
        key2_len = key2.length
        key3 = newText.match(reg3).to_s.downcase
        key3_len = key3.length
        key4 = newText.match(reg4).to_s.downcase
        key4_len = key4.length
        key5 = newText.match(reg5).to_s.downcase
        key5_len = key5.length
        leftText.gsub!(sreg," ")
        rightText.gsub!(sreg," ")
        rightText = rightText[0,80]
        if leftText.length < 60
          leftText = " " * (60-leftText.length) + leftText
        else
          leftText = leftText[leftText.length-60,leftText.length]
        end
        leftWords = Array.new
        leftText.downcase.scan(reg) do |word|
          leftWords << [$&,[$`.length,$&.length]]
        end
        leftWords.reverse!
        if leftWords.length < 6
          (5-leftWords.length).times do |i|
            leftWords << ["",[0,0]]
          end
        end
        rightWords = Array.new
        rightText.downcase.scan(reg) do |word|
          rightWords << [$&,[$`.length+60+key.length,$&.length]]
        end
        if rightWords.length < 10
          (9-rightWords.length).times do |i|
            rightWords << ["",[0,0]]
          end
        end
        db.execute("INSERT INTO conc_idx_data (id,file_name,encoding,key,left_text,right_text,key_pos_loc,key_local_pos,key_pos_len,l5,l4,l3,l2,l1,keyw,r1,r2,r3,r4,r5,r6,r7,r8,r9,l5_pos_loc,l5_pos_len,l4_pos_loc,l4_pos_len,l3_pos_loc,l3_pos_len,l2_pos_loc,l2_pos_len,l1_pos_loc,l1_pos_len,r1_pos_loc,r1_pos_len,r2_pos_loc,r2_pos_len,r3_pos_loc,r3_pos_len,r4_pos_loc,r4_pos_len,r5_pos_loc,r5_pos_len,r6_pos_loc,r6_pos_len,r7_pos_loc,r7_pos_len,r8_pos_loc,r8_pos_len,r9_pos_loc,r9_pos_len,path,file_id,key2,key3,key4,key5,key2_pos_len,key3_pos_len,key4_pos_len,key5_pos_len) values (null,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",File.basename(file),0,key,leftText,rightText,keyPos,leftText.length,key.length,leftWords[4][0],leftWords[3][0],leftWords[2][0],leftWords[1][0],leftWords[0][0],key.downcase,rightWords[0][0],rightWords[1][0],rightWords[2][0],rightWords[3][0],rightWords[4][0],rightWords[5][0],rightWords[6][0],rightWords[7][0],rightWords[8][0],leftWords[4][1][0],leftWords[4][1][1],leftWords[3][1][0],leftWords[3][1][1],leftWords[2][1][0],leftWords[2][1][1],leftWords[1][1][0],leftWords[1][1][1],leftWords[0][1][0],leftWords[0][1][1],rightWords[0][1][0],rightWords[0][1][1],rightWords[1][1][0],rightWords[1][1][1],rightWords[2][1][0],rightWords[2][1][1],rightWords[3][1][0],rightWords[3][1][1],rightWords[4][1][0],rightWords[4][1][1],rightWords[5][1][0],rightWords[5][1][1],rightWords[6][1][0],rightWords[6][1][1],rightWords[7][1][0],rightWords[7][1][1],rightWords[8][1][0],rightWords[8][1][1],file,idx,key2,key3,key4,key5,key2_len,key3_len,key4_len,key5_len)
      end
      idx += 1
    end  
  end
end

db.execute("create index keyindex on conc_idx_data(keyw)")
db.execute("create index keyindex2 on conc_idx_data(key2)")
db.execute("create index keyindex3 on conc_idx_data(key3)")
db.execute("create index keyindex4 on conc_idx_data(key4)")
db.execute("create index keyindex5 on conc_idx_data(key5)")

print "#{Time.new - t}/#{totalTokens}"