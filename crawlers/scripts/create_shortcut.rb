#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

# 前提
# - win32-shortcutが必要です。
#   > gem install win32-shortcut

require 'pathname'
require 'win32/shortcut'

require 'my/config'
require 'mtk/import'
require_relative 'commons'
require_relative 'save_history'

include Win32

module Scripts; end

module Scripts::CreateShortcut
  SHORTCUT_DIR = My::CONFIG::dest_dir + 'crawler/shortcuts'

  # 画像閲覧用のショートカットを作成
  def self.execute src
    src = to_pathname(src)
    dest = SHORTCUT_DIR + calc_dest_basename(src)

    Shortcut.new(dest.to_s){|shortcut|
      shortcut.description = 'View image'
      shortcut.path = src.to_s
      shortcut.show_cmd = Shortcut::SHOWNORMAL
      shortcut.working_directory = src.dirname.to_s
      #shortcut.hotkey = 'CTRL+SHIFT+F'
    }
  end

  #'/**/a/b/r18/c.jpg' => 'b_r18_c.lnk'
  def self.calc_dest_basename src
    src = to_pathname(src)
    names = ["#{src.basename('.*')}.lnk"]
    src.dirname.ascend do |path|
      names << path.basename
      break unless path.basename.to_s =~ /r18/i
    end
    names.reverse!
    return names.join('_')
  end

  def self.to_pathname src
    return src.is_a?(String) ? Pathname(File.expand_path(src)) : src
  end


end

if $0 == __FILE__
  include Scripts
  script_header(:filename)

  image = ARGV[0]
  CreateShortcut.execute(image)
  SaveHistory.execute(image)
end
