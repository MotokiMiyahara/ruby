# vim:set fileencoding=utf-8:

#require 'pathname'
#require 'pp'
require 'digest/md5'
require 'pstore'
#require 'mtk/util'

#exit if (defined?(Ocra))

OUT_SZ7 = File.expand_path('tmp_uniq.sz7', __dir__)
LOG_FILE = File.expand_path('nodup.log', __dir__)
DB_FILE = File.expand_path('db.dat', __dir__)

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
    uniq_images = images.uniq(&:md5)

    puts "#{images.size} -> #{uniq_images.size}"

    write_sz7(OUT_SZ7, uniq_images)
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
    images = @db.images(pathes)
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

class Image < Struct.new(:path, :md5); end

class Db 
  def initialize
    @db = PStore.new(DB_FILE)
  end

  def images(pathes)
    @db.transaction do
      images = pathes.map {|p|
        path = p.gsub('/', '\\')
        begin
          @db[path] ||= Image.new(path, Digest::MD5.file(path).hexdigest)
        rescue Errno::ENOENT => e
          nil
        end
      }
      images.compact!
      images
    end
  end
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

