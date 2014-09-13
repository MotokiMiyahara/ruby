# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'timeout'
require 'net/http'

require 'nokogiri'
require 'parallel'

require 'my/config'
require 'mtk/util'
require 'mtk/net/firefox'

require_relative '../../util'
require_relative '../../errors'
require_relative 'config'
require_relative 'remote_image'
require_relative 'modules'

module Crawlers::DanbooruClones::Konachan

  class Crawler < Crawlers::DanbooruClones::Core::AbstractCrawler
    def initialize(*args)
      super(Config, *args)
    end

    def page_offset
      return 1
    end

    def max_image_count_per_page
      # max 100(Konachan APIの仕様上) 
      return 100
    end

    def remote_image_class
      return RemoteImage
    end

    def page_count_uri
      q = {
        tags:  keyword,
        limit: 1,
      }

      query = URI.encode_www_form(q)
      return URI("http://konachan.com/post.xml?#{query}")
    end

    def page_uri(page)
      q = {
        tags:  keyword,
        limit: image_count_per_page,
        page:  page,
      }

      query = URI.encode_www_form(q)
      return URI("http://konachan.com/post.xml?#{query}")
    end
  end
end



if $0 == __FILE__ 
  exit
  KEYWORDS = [
    'topless',
    #'smile nipples pussy -amputee -nude_filter',
  ]

  tlog('start')
  KEYWORDS.each do |keyword|
    crawl(keyword)
  end
  tlog('end')
end

