puts ARGV.to_s

RecordSet = Struct.new( :id, :text, :binary, :b64) 

def pack_8_a (ary)
  i32 = 0
  ary.each do |x|
    i32 = i32 * 256 + x
  end
  i32
end

def pluck_record_id (record)
  record[0,2].pack('C*')  
end

def pluck_text (set)
  if set['id'] == '52' then
    text = set['binary'][0,117].pack('C*')
    binary = set['binary'].drop(117)
    b64 = [binary.pack('C*')].pack('m0')
  else
    text = set['binary'].pack('C*')
    binary = set['binary']
    b64 = ''
  end
  
  RecordSet.new(set['id'], text, binary, b64)
end

def extract_record (file_handle)
  first_4 = []
  (0..3).each do |x|
    first_4 << file_handle.readbyte
  end
  rec_len = pack_8_a(first_4)

  record = []
  (0...rec_len).each do |x|
    record << file_handle.readbyte
  end
  record
end
idf = []
icl_source = File.open(ARGV.first, 'rb') do |aFile|
  puts 'opened file'
  rec_len = 0
  fp = 0
   while (!aFile.eof?) do
    record = extract_record (aFile)
    record_id = pluck_record_id(record)
    set = RecordSet.new(record_id, '', record)
    set = pluck_text(set)
    #  [[ uncomment the following to view the ICL binary dump - if present]]
    # puts '-------------=======================---------------'
    # puts set['id']
    # puts '       ------***********************---------------'
    # if record_id == '52' then
    #   puts set[:b64][0, 80]
    # end
    #  puts '-------------binary---------------'
    #puts set['text']
    #puts '-------------=======================---------------'
    idf << set
  end
end if ARGV.first

depth = 0
inside_icf = false
inside_cash_letter = false
inside_bundle = false
inside_item = false

detail_record = false
idf.each do |rs|
  case rs[:id]
  when '01'
    inside_icf = true
    
  when '10'
    inside_cash_letter = true
    
  when '20'
    inside_bundle = true
    
  when '25', '61'
    puts '---- ' << rs[:text]
    if inside_item || detail_record then
      # start new item actions
      detail_record = rs
    end
    inside_item = true

  when '52'
    puts  '---- ----- ' << rs[:b64][0, 40]
    
  when '68'
    puts '---- ' << rs[:text]

  when '70'
    inside_item = false
    detail_record = false

  when '90'
    inside_item = false
    inside_bundle = false

  when '99'
    inside_item = false
    inside_bundle = false
    inside_cash_letter = false
  else
    0
  end
  
  spacer = ''
  spacer << ' ' if inside_cash_letter
  spacer << ' ' if inside_bundle
  spacer << ' ' if inside_item
  puts spacer << rs[:id]
end

puts 'end'
