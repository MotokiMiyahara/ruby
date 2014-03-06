# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

#require 'pathname'
#require 'pp'
require_relative 'db'

OUT_SZ7 = File.expand_path('tmp_uniq.sz7', __dir__)
LOG_FILE = File.expand_path('nodup.log', __dir__)

#OUT_SZ7  = 'tmp_uniq.sz7'
#LOG_FILE = 'nodup.log'
#DB_FILE  = 'db.dat'

class Nodup
  def initialize
    @db = Db.new
  end
  def main
    sz7 = ARGV[0]
    puts "in: #{sz7}"
    exit unless sz7

    images = read_sz7(sz7)
    write_sz7(OUT_SZ7, images)
    invoke_viewer(OUT_SZ7)
  end

  def write_sz7(file, images)
    open(file, 'wb:SJIS') do |f|
      images.each do |image|
        f.print(image.path, "\r\n")
      end
      f.print("\r\n")
    end
  end

  def read_sz7(file)
    pathes = File.read(file, encoding: 'SJIS').split("\n")
    images = @db.uniq_images(pathes)
    return images
  end

  def invoke_viewer(file)
    `"C:\\my\\tools\\MassiGra045\\MassiGra.exe" #{OUT_SZ7.encode('SJIS')}`
  end
end




def with_log(&block)
  $stdout = $stderr = File.open(LOG_FILE, "w:UTF-8")
  raise 'block is required' unless block
  block.call
ensure
  $stdout = STDOUT
  $stderr = STDERR
end



if $0 == __FILE__
  #tlog('s')
  #if (ENV.key?("OCRA_EXECUTABLE"))
    # ここは EXE ファイル実行中のみ通る
     with_log{Nodup.new.main}
  #else
  #  Nodup.new.main
  #end
  #tlog('e')
end

