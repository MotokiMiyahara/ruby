# vim:set fileencoding=utf-8:
#

require 'mtk/import'
require 'pstore'
require_relative '../config'


module Crawlers; end

# 画像ディレクトリ => 画像ファイル　の辞書データ
class Crawlers::ImageStore
  def initialize
    Crawlers::Config.make_dirs
    @db = PStore.new(Crawlers::Config.save_file_of_last_shown_image, true)
  end
  
  # ---------------------------------------------
  def [](key)
    key = clean_key(key)
    @db.transaction do
      return @db[key]
    end
  end

  def store_image(image_path)
    dir_path = image_path.to_pathname.dirname
    key = clean_key(dir_path)
    value = clean_value(image_path)
    @db.transaction do
      @db[key] = value
    end
  end

  def delete(key)
    key = clean_key(key)
    @db.transaction do
      @db.delete(key)
    end
  end

  def clean_path(path)
    return path.to_s.encode('UTF-8').gsub('\\', '/').to_pathname.cleanpath
  end
  alias clean_key clean_path
  alias clean_value clean_path

  def log
    @db.transaction do
      @db.roots.each do |k|
        v = @db[k]

        #pp k
        puts "#{k} #{k.to_s.encoding} => #{v}"
      end
    end
  end
  
  # ---------------------------------------------
  # 画像のディレクトリを手動で移動した場合にDBを更新するために使用する
  # @param current_dir [Pathname] 画像ディレクトリ　　　　(絶対パス)
  # @param src_dir     [Pathname] 分類用のサブディレクトリ(current_dirからの相対パス)
  # @param dest_dir    [Pathname] 移動先のディレクトリ    (current_dirからの相対パス)
  def rename_dir(current_dir, src_dir, dest_dir)
    current_dir = clean_path(current_dir)
    main_dir = current_dir.join(src_dir)

    @db.transaction do
      @db.roots.each do |key|

        next unless key.to_s =~ /^#{Regexp.quote(main_dir.to_s)}/

        value = @db[key]
        next unless value

        new_path = method(:calc_new_path).to_proc.curry[current_dir, dest_dir]
        new_key   = new_path[key]
        new_value = new_path[value]

        @db.delete(key)
        @db[new_key] = new_value

        puts "rename #{key} => #{new_key}"
      end
    end
  end
  
  def calc_new_path(current_dir, dest_dir, path)
      relative_path = path.relative_path_from(current_dir)
      new_path = current_dir.join(dest_dir, relative_path)
      #puts new_path
      return new_path
  end

end

def do_rename()
  require_relative 'constants'
  db = ImageStore.new

  #db.rename_dir(Pixiv::PIXIV_DIR, '大妖精', '東方Project')
  dirs = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    忍野忍
  EOS

  pp dirs
  dirs.each do |dir|
    db.rename_dir(Pixiv::PIXIV_DIR, dir, '化物語')
  end

end

if $0 == __FILE__
  include Crawlers
  db = ImageStore.new
  #db.log

  #do_rename
end

