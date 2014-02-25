#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'mtk/import'
require_relative 'commons'
require_relative '../util'

module Scripts; end
class Scripts::ViewInPixiv
  NOT_FOUND_URI = URI.parse("file:///#{Pathname(__dir__).expand_path.join('html/NotFound.html')}")
  class << self
    include Crawlers::Util

    public 
    def execute(image)
      basename =  Pathname(image).basename.to_s
      uri = get_uri(basename)
      invoke_browser(uri)
    end

    private
    def get_uri(basename)
      case basename
      when /^pixiv_(\d+)(?:_big_p\d+)?\.\w+/
        # pixiv
        "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{$1}"

      when /^gelbooru_(\d+)_/
        "http://gelbooru.com/index.php?page=post&s=view&id=#{$1}"

      when /^(\d+)(?:_big_p\d+)?\.\w+/
        # maybe pixiv
        "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{$1}"

      else
        NOT_FOUND_URI
      end
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header
  image = ARGV[0]
  ViewInPixiv.execute(image)
end
