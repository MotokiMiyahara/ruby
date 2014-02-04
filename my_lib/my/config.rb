# vim:set fileencoding=utf-8:

require'my/my'
require'fileutils'
require'pathname'
require'pp'

module My
  class Config

    def dest_dir
      Pathname.new('/samba/generated_data')
    end

    # ---------------------
    # :section: バックアップ
    # ---------------------
    def backup_sources
      %w{C:/GitHub/study}.map(&Pathname.method(:new))
    end

    def backup_dests
      %w{C:/backup I:/backup/study}.map(&Pathname.method(:new))
    end
  end
  CONFIG = Config.new
end

