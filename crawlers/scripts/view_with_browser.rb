#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'mtk/import'

require_relative 'commons'
require_lib 'util'

module Scripts; end
class Scripts::ViewInPixiv
  NOT_FOUND_URI = URI.parse("file:///#{Pathname(__dir__).expand_path.join('html/NotFound.html')}")
  class << self
    include Crawlers::Util

    public 
    def execute(image)
      basename =  Pathname(image).basename.to_s
      uri = get_uri(basename)
      puts uri
      invoke_browser(uri)
    end

    private
    def get_uri(basename)
      ignore_headers = %w{
         waifu 
         kaizou
         kaiten
         k 
      }
      header_pattern = "^(?:(?:#{ignore_headers.join('|')})_)+"

      basename = basename.sub(/^#{header_pattern}/, '')

      case basename
      #when /^pixiv_(\d+)(?:_big_p\d+)?\.\w+/
      #when /^pixiv_(\d+)(?:_(?:big_)?p\d+)?\.\w+/
      when /^pixiv_(\d+)(?:(?:_big)?_p\d+)?\.\w+/
        # pixiv
        "http://www.pixiv.net/member_illust.php?mode=medium&illust_id=#{$1}"

      when /^gelbooru_(\d+)/
        "http://gelbooru.com/index.php?page=post&s=view&id=#{$1}"

      when /^konachan_(\d+)/
        "http://konachan.com/post/show/#{$1}/"

      when /^yande\.?re[_\s](\d+)/
        "https://yande.re/post/show/#{$1}/"

      #when /^(\d+)(?:_(?:big_)p\d+)?\.\w+/
      when /^(\d+)(?:(?:_big)?_p\d+)?\.\w+/
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
  puts image
  ViewInPixiv.execute(image)
end
