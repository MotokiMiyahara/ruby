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

module Crawlers::DanbooruClones::Gelbooru

  class Crawler < Crawlers::DanbooruClones::Core::AbstractCrawler
    def initialize(*args)
      super(Config, *args)
    end

    def page_offset
      return 0
    end

    def max_image_count_per_page
      # max 200(Gelbooru APIの仕様上) 
      return 200
    end

    def remote_image_class
      return RemoteImage
    end

    def page_count_uri
      q = {
        page:  'dapi',
        s:     'post',
        q:     'index',
        tags:  keyword,
        limit: 1,
        pid:   0,
      }

      query = URI.encode_www_form(q)
      return URI("http://gelbooru.com/index.php?#{query}")
    end

    def page_uri(page)
      q = {
        page:  'dapi',
        s:     'post',
        q:     'index',
        tags:  keyword,
        limit: image_count_per_page,
        pid:   page,
      }

      query = URI.encode_www_form(q)
      return URI("http://gelbooru.com/index.php?#{query}")
    end
  end
end



if $0 == __FILE__ 
  exit

  def crawl(keyword)
    Crawlers::DanbooruClones::Gelbooru::Crawler.new(
      keyword,
      news_only: true,
      noop: false
    ).crawl
  end

  KEYWORDS = [
    'nude_filter',
    #'smile nipples pussy -amputee -nude_filter',
  ]

  tlog('start')
  KEYWORDS.each do |keyword|
    crawl(keyword)
  end
  tlog('end')
end

