#!/usr/bin/env ruby
# { terriblefs filename => [build dir filename, convert_linefeeds, num sectors] }
FILES = {
  "MSRBTRCD" => :mbr,
  "KERN_BIN" => ["kernel-commandline.bin", false, 4],
  "BEEMOVIE" => ["bee-movie.txt", true, 128],
  "BEEMVIE2" => ["back-to-back-bee-movie.txt", true, 256],
  "TEST_BIN" => ["test.bin", false, 1]
}

out_fn = "terriblefs.bin"

def die(msg)
  STDERR.puts msg
  exit 1
end

if ARGV[0] == "makefile"
  required_files = FILES.values.find_all{|v| v.is_a? Array}.map(&:first)
  puts "#{out_fn}: #{$0} #{required_files.join(" ")}
\truby #{$0}"
  exit 0
end

FILES.each do |tfn, arr|
  if tfn.size != 8
    die "Name must be exactly 8 characters"
  end
  if arr.is_a?(Array) && File.size(arr.first) > arr[2]*512
    die "Sector size #{arr[2]} too small for #{tfn}:#{arr[0]}"
  end
end

#first sector is mbr
#next 8 sectors are the metadata table
sector_offset = 9
File.open(out_fn, "wb") do |f|
  FILES.each do |tfn, arr|
    if arr == :mbr
      die "mbr file must be first" unless sector_offset == 9
      f.write tfn
      f.write [0, 512].pack("L<L<")
    else
      (rfn, conv, ss) = arr
      arr.push(sector_offset)

      old_pos = f.tell
      f.seek((sector_offset*512)-512)
      new_pos = f.tell
      if conv
        data = File.read(rfn)
        new_data = data.encode( data.encoding, universal_newline: true ).encode( data.encoding, crlf_newline: true )
        f.write(new_data)
      else
        File.open(rfn, "rb") do |rf|
          IO.copy_stream(rf, f)
        end
      end
      out_length = f.tell - new_pos
      f.seek(old_pos)

      if out_length > ss*512
        die "Sector size #{ss} too small for #{tfn}:#{rfn}"
      end
      
      f.write tfn
      f.write [sector_offset, out_length].pack("L<L<")
      sector_offset += ss
    end
    die "I'm bad at writing" unless f.tell % 16 == 0
  end
  f.write 0x80.chr
  7.times{ f.write 0x00.chr }
  f.write [sector_offset, 0].pack("L<L<")
end

