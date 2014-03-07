# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'digest/md5'
require 'pstore'

class Image

  class <<self
    def create_and_calc_md5(a_path)
      path = dos_path(a_path)
      return Image.new(path, Digest::MD5.file(path).hexdigest)
    end

    def dos_path(path)
      return path.gsub('/', '\\')
    end
  end

  attr_reader :path, :md5
  def initialize(path, md5)
    @path = self.class.dos_path(path)
    @md5 = md5
  end
end

class Db 
  DB_FILE = File.expand_path('../watched/db/db.dat', __dir__)
  def initialize
    @db = PStore.new(DB_FILE)
  end

  def uniq_images(pathes)
    @db.transaction do
      images = pathes.map {|p|
        begin
          path = Image.dos_path(p)
          @db[path] ||= Image.create_and_calc_md5(path)
        rescue Errno::ENOENT => e
          nil
        end
      }
      images.compact!
      images.uniq!(&:md5)
      images
    end
  end

  def regist_images(rows)
    @db.transaction do
      rows.each do |row|
        path = Image.dos_path(row[:path])
        @db[path] ||= Image.new(path, row[:md5])
      end
    end
  end
end
