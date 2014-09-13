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

module Konachan

  class Crawler < Crawlers::DanbooruClones::Core::AbstractCrawler
    def initialize(*args)
      super(Konachan::Config, *args)
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

  #  # オプション引数の説明
  #  #   news_modeが真のとき
  #  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #  class Crawler
  #    include Crawlers::Util
  #
  #    VERBOSE = false
  #    THREAD_COUNT_DOWNLOAD_IMAGES = 10
  #
  #    MAX_IMAGE_COUNT_PER_PAGE = 100 # max 200(Konachan APIの仕様上)
  #
  #    def initialize(
  #          keyword,
  #          news_only:  false,
  #          news_save:  true,
  #          parent_dir: nil,
  #          noop:       true,
  #          min_page:   1,
  #          max_page:   nil,
  #          image_count_per_page: :auto
  #        )
  #
  #
  #      @keyword = keyword
  #      @news_only = news_only
  #      @news_save = news_save
  #      @dest_dir = calc_dest_dir(keyword, parent_dir)
  #      @min_page = min_page
  #      @max_page = max_page
  #      @noop = noop
  #
  #      @image_count_per_page = calc_image_count_per_page(image_count_per_page)
  #
  #      @firefox = Mtk::Net::Firefox.new
  #      @dest_dir.mkpath unless @noop || @dest_dir.exist?
  #    end
  #
  #
  #
  #    public
  #    def crawl
  #      if @noop
  #        log_status
  #      else
  #        do_crawl
  #      end
  #    end
  #
  #
  #    private
  #    def log_status
  #      log '---------------------------'
  #      log "@image_count_per_page=#{@image_count_per_page}"
  #      log "@dest_dir=#{@dest_dir}"
  #      log "@keyword=#{@keyword}"
  #      log 
  #    end
  #
  #    def do_crawl
  #      max_page = [@max_page, fetch_max_page].compact.min
  #
  #      (@min_page..max_page).each do |page|
  #        crawl_page(page)
  #      end
  #    rescue CancellError => e
  #      log e.message
  #    end
  #
  #    def crawl_page(page)
  #      log "index: page=#{page} #{ident_message}"
  #
  #      q = {
  #        tags:  @keyword,
  #        limit: @image_count_per_page,
  #        page:   page,
  #      }
  #
  #      query = URI.encode_www_form(q)
  #      uri = "http://konachan.com/post.xml?#{query}"
  #
  #      doc = get_document(uri)
  #
  #      posts = doc.css('posts post')
  #      remote_images = posts.map{|post|
  #        RemoteImage.new(
  #          post, @dest_dir, @news_save, @firefox)
  #      }
  #
  #      #pp remote_images
  #      #raise
  #
  #      remote_images.reject!{|image| image.search_file.exist?}
  #      Parallel.each(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|image| image.download}
  #
  #      if @news_only && remote_images.empty?
  #        raise CancellError, "Cancell crawling, because not found new images in {page: #{page}, keyword: '#{@keyword}'} (news_only)" 
  #      end
  #    end
  #
  #    def fetch_max_page
  #      image_count = fetch_image_count
  #      page_count = image_count.quo(@image_count_per_page).ceil
  #      #max_page = page_count - 1
  #      max_page = page_count
  #      return max_page
  #    end
  #
  #    def fetch_image_count
  #      q = {
  #        tags:  @keyword,
  #        limit: 1,
  #      }
  #
  #      query = URI.encode_www_form(q)
  #      uri = "http://konachan.com/post.xml?#{query}"
  #      log "api-uri='#{uri}'"
  #
  #      retry_fetch do
  #        doc = get_document(uri)
  #        posts = doc.at_css('posts')
  #        raise Crawlers::DataSourceError, "document doesn't have <posts>-tag." unless posts
  #        return posts[:count].to_i
  #      end
  #    end
  #
  #    def calc_dest_dir(keyword, rerative_parent_dir)
  #      rerative_parent_dir ||= Pathname('.')
  #      dest_dir = SEARCH_DIR + rerative_parent_dir + calc_dest_dir_basename
  #      return dest_dir
  #    end
  #
  #    def calc_dest_dir_basename
  #      words = @keyword.split(/\s+/)
  #      words.map!{|word|
  #        next word if word.start_with?('-')
  #        next "【#{word}】"
  #      }
  #      return fix_basename(words.join('_'))
  #    end
  #
  #    # @return [Integer]
  #    def calc_image_count_per_page(var)
  #      case var
  #      when :auto
  #        @dest_dir.exist? ? 30 : MAX_IMAGE_COUNT_PER_PAGE
  #      when :max
  #        MAX_IMAGE_COUNT_PER_PAGE
  #      when Integer
  #        var
  #      else
  #        raise ArgumentError, "image_count_per_page is 'auto' or number"
  #      end
  #    end
  #
  #    def get_document(uri, *rest)
  #      retry_fetch(message: uri) do
  #        html = @firefox.get_html_as_utf8(uri, *rest)
  #        #doc = Nokogiri::HTML(html)
  #        doc = Nokogiri::XML(html)
  #        return doc
  #      end
  #    end
  #
  #    def ident_message
  #      return "keyword='#{@keyword}'"
  #    end
  #  end
  #
  #  class CancellError < Exception; end
  #end
  #
  #
  #def crawl(keyword)
  #  Konachan::Crawler.new(
  #    keyword,
  #    news_only: true,
  #    noop: false,
  #    max_page: 2
  #  ).crawl
  #end



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

