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
    def execute src
      src = src.to_pathname
      dest = Crawlers::Config.keep_dir.join(src.basename)

      return if src.dirname == dest.dirname
      FileUtils.copy(src, dest)
      FileUtils.touch(dest)
    end
  end

end

if $0 == __FILE__
  include Scripts
  script_header(:filename)
  image = ARGV[0]
  CopyAndTouch.execute(image)
end
