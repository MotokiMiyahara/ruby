# vim:set fileencoding=utf-8:

require 'pathname'
require 'pp'
require 'mtk/import'
require 'fileutils'

require_relative 'constants'



def log_pathname pathname
  pp pathname.to_s.encode('UTF-8')
end

def each_file(dir, &block)
  raise unless block
  dir.each_child do |f|
    #pp f.basename.to_s.encode('utf-8')
    next if f ==  Pixiv::ALL_IMAGE_DIR
    next if ['.', '..', 'r18', 'news', 'Thumbs.db'].include? f.basename.to_s

    block.call(f) if f.file?
    each_file(f, &block) if f.directory?
  end
end

def regularize_image img
    regular_file = Pixiv::ALL_IMAGE_DIR.join(img.basename)
    if regular_file.exist?
      img.unlink
      log_pathname img
    else
      img.rename(regular_file)
    end

    img.make_link(regular_file)
end

if $0 == __FILE__
  tlog('s')
  each_file('H:\generated_data\crawler\pixiv\化物語\忍野忍'.to_pathname) do |img|
  #each_file(Pixiv::PIXIV_DIR) do |img|
    #log_pathname img unless img.basename.to_s.encode('utf-8') =~ /^\d+/
    #log_pathname img
    regularize_image img
  end
  tlog('e')
end



