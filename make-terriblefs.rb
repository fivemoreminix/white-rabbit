#!/usr/bin/env ruby
# { terriblefs filename => [build dir filename, convert_linefeeds, num sectors] }
FILES = { "KERN_BIN" => ["pretend-kernel.txt", true, 1] }

out_fn = "terriblefs.bin"

def die(msg)
  STDERR.puts msg
  exit 1
end

if ARGV[0] == "makefile"
  puts "#{out_fn}: #{FILES.values.map{|v| v[0]}.join(" ")}
\t#{$0}"
  exit 0
end

FILES.each do |tfn, (rfn, conv, ss)|
  if tfn.size != 8
    die "Name must be exactly 8 characters"
  end
  if File.size(rfn) > ss*512
    die "Sector size #{ss} too small for #{tfn}:#{rfn}"
  end
end

#first sector is mbr
#next 8 sectors are the metadata table
sector_offset = 9
File.open(out_fn, "wb") do |f|
  FILES.each do |tfn, arr|
    (rfn, conv, ss) = arr
    arr.push(sector_offset)
    f.write tfn
    f.write [sector_offset, File.size(rfn)].pack("L<L<")
    sector_offset += ss
  end
  f.write 0x80.chr
  7.times{ f.write 0x00.chr }
  f.write [sector_offset, 0].pack("L<L<")

  file_data_start = 256*16 # 256 entries, each entry is 16 bytes
  FILES.each do |tfn, (rfn, conv, ss, so)|
    f.seek(file_data_start + (so*512))
    if conv
      data = File.read(rfn)
      new_data = data.encode( data.encoding, universal_newline: true ).encode( data.encoding, crlf_newline: true )
      f.write(new_data)
    else
      File.open(rfn, "rb") do |rf|
        IO.copy_stream(rf, f)
      end
    end
  end
end

