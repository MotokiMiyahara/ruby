#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'mtk/import'
require_relative 'commons'

require_lib 'config'

module Scripts; end
class Scripts::CopyAndTouch
  #KEEP_DIR = Pathname('C:/Documents and Settings/mtk/デスクトップ/keep')
  class << self
    def execute(src, dest_dir)
      src = Pathname(src)
      dest = dest_dir.join(src.basename)

      puts dest

      return if src.dirname == dest.dirname
      FileUtils.copy(src, dest)
      FileUtils.touch(dest)
    end

  end
end

if $0 == __FILE__
  class Main
    class << self
      #include Scripts

      def main
        #script_header(:filename)

        opts = parse_opt!
        dest_dir = opts[:dest_dir] || Crawlers::Config.keep_dir

        if ARGV.size < 1
          puts 'usage: ruby copy_and_touch.rb [opts] {filename}'
          exit
        end

        image = ARGV[0]
        Scripts::CopyAndTouch.execute(image, dest_dir)

      end

      def parse_opt!
        opt = {}
        parser = OptionParser.new
        parser.on('--dest_dir=VAL', 'dest_dir'){|v| opt[:dest_dir] = Pathname(v)}
        parser.parse!(ARGV)
        return opt
      end
    end
  end

  Main.main
end
