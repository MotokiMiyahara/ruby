# vim:set fileencoding=utf-8:

require 'pathname'
require 'zlib'
require 'archive/tar/minitar'

require 'mtk/import'

module Mtk; end
module Mtk::Util; end

module Mtk::Util::Archive
  include ::Archive::Tar
  extend self

  def included(klass)
    klass.extend self
  end

  def tar_cvf(src_dir, dest)
    File.open(dest, 'wb') do |tar|
      append_to_tar(tar, src_dir.to_pathname)
    end
  end

  def tar_zcvf(src_dir, dest)
    Zlib::GzipWriter.wrap(File.open(dest, 'wb')) do |tar|
      append_to_tar(tar, src_dir.to_pathname)
    end
  end

  private 
  def append_to_tar tar, src_dir
    Dir.chdir(src_dir.dirname) do
      Minitar.pack(src_dir.basename.to_s, tar)
    end
  end
end


if $0 == __FILE__
  #include Mtk::Util::Archive
  #tar_zcvf('C:\noblish\data', 'test.tar.gz')
end


