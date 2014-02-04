# vim:set fileencoding=utf-8:

require 'date'
require 'tempfile'
require 'fileutils'
require 'mtk/import'
require 'mtk/util/archive'
require 'my/config'

module My
  class Backup
    include Mtk::Util::Archive

    def initialize
      @datetime = DateTime.now
    end

    def backup
      CONFIG.backup_sources.each do |src_dir|
        backup_dir src_dir
      end
    end

    private 
    def backup_dir src_dir
      tar = Tempfile.open('backup') do |f|
        tar_zcvf(src_dir, f)
        Pathname.new(f.path)
      end

      CONFIG.backup_dests.map{|dest_dir| calc_backup_name src_dir, dest_dir}.each do |dest_file|
        FileUtils.copy_file(tar, dest_file)
        dest_file.tap
      end

    end

    def calc_backup_name src_dir, dest_dir
      prefix = src_dir.basename.to_s 
      prefix += @datetime.strftime('%Y%m%d_')

      idx = 1
      result = nil
      loop do
        result = dest_dir + (prefix + idx.to_s + '.tar.gz')
        return result unless result.exist?
        idx += 1
      end
    end
  end
end

if $0 == __FILE__
  My::Backup.new.backup
end
