#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'mtk/import'
require_relative 'commons'
require_relative '../util'

module Scripts; end
class Scripts::ViewInPixiv
  class << self
    include Crawlers::Util
    def execute(image)
      unless Pathname(image).basename.to_s =~ %r{(\d+)(?:_big_p\d+)?\.\w+}
        p 'not match'
      end

      uri = "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{$1}"
      invoke_browser(uri)
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header
  image = ARGV[0]
  ViewInPixiv.execute(image)
end
