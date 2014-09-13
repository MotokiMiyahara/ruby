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

require 'mtk/syntax'
require_relative '../../util'
require_relative '../../errors'
require_relative 'modules'


module Crawlers::DanbooruClones::Core

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  class AbstractCrawler
    using Mtk::Syntax::Abstract
    include Crawlers::Util

    THREAD_COUNT_DOWNLOAD_IMAGES = 10

    # to do
    MAX_IMAGE_COUNT_PER_PAGE = 100 # max 100(Konachan APIの仕様上) 

    def initialize(
          config,
          keyword,
          news_only:  false,
          news_save:  true,
          parent_dir: nil,
          noop:       true,
          min_page:   0 + page_offset,
          max_page:   nil,
          image_count_per_page: :auto
        )

      @config = config

      @keyword = keyword
      @news_only = news_only
      @news_save = news_save
      @dest_dir = calc_dest_dir(keyword, parent_dir)
      @min_page = min_page
      @max_page = max_page
      @noop = noop

      @image_count_per_page = calc_image_count_per_page(image_count_per_page)

      @firefox = Mtk::Net::Firefox.new
      @dest_dir.mkpath unless @noop || @dest_dir.exist?
    end

    # サブクラス用の定義--------
    private
    attr_reader :keyword
    attr_reader :image_count_per_page

    # 最初のページの番号(0 or 1)
    def_abstract :page_offset

    # 1ページで取得できる最大の件数
    def_abstract :max_image_count_per_page

    def_abstract :page_count_uri
    def_abstract :page_uri
    def_abstract :remote_image_class


    # ----------------------------
    public
    def crawl
      if @noop
        log_status
      else
        do_crawl
      end
    end


    private
    def log_status
      log '---------------------------'
      log "@image_count_per_page=#{@image_count_per_page}"
      log "@dest_dir=#{@dest_dir}"
      log "@keyword=#{@keyword}"
      log 
    end

    def do_crawl
      min_page = @min_page
      max_page = [@max_page, fetch_max_page].compact.min

      (min_page..max_page).each do |page|
        crawl_page(page)
      end
    rescue CancellError => e
      log e.message
    end

    def crawl_page(page)
      uri = page_uri(page)

      log "index: page=#{page} #{ident_message}"
      log "uri: #{uri}"

      doc = get_document(uri)
      posts = doc.css('posts post')
      remote_images = posts.map{|post|
        create_remote_image(post)
      }

      #pp remote_images
      #raise

      remote_images.reject!{|image| image.search_file.exist?}
      Parallel.each(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|image| image.download}

      if @news_only && remote_images.empty?
        raise CancellError, "Cancell crawling, because not found new images in {page: #{page}, keyword: '#{@keyword}'} (news_only)" 
      end
    end

    def fetch_max_page
      image_count = fetch_image_count
      page_count = image_count.quo(@image_count_per_page).ceil
      max_page = page_count - 1 + page_offset
      return max_page
    end

    def fetch_image_count
      uri = page_count_uri

      log "api-uri='#{uri}'"

      retry_fetch do
        doc = get_document(uri)
        posts = doc.at_css('posts')
        raise Crawlers::DataSourceError, "document doesn't have <posts>-tag." unless posts
        return posts[:count].to_i
      end
    end

    def calc_dest_dir(keyword, rerative_parent_dir)
      rerative_parent_dir ||= Pathname('.')
      dest_dir = @config.search_dir + rerative_parent_dir + calc_dest_dir_basename
      return dest_dir
    end

    def calc_dest_dir_basename
      words = @keyword.split(/\s+/)
      words.map!{|word|
        next word if word.start_with?('-')
        next "【#{word}】"
      }
      return fix_basename(words.join('_'))
    end

    # @return [Integer]
    def calc_image_count_per_page(var)
      case var
      when :auto
        @dest_dir.exist? ? 30 : max_image_count_per_page
      when :max
        max_image_count_per_page
      when Integer
        var
      else
        raise ArgumentError, "image_count_per_page is 'auto' or number"
      end
    end

    def get_document(uri, *rest)
      retry_fetch(message: uri) do
        html = @firefox.get_html_as_utf8(uri, *rest)
        doc = Nokogiri::XML(html)
        return doc
      end
    end

    def ident_message
      return "keyword='#{@keyword}'"
    end

    # ---------------------------------
    def create_remote_image(post)
      return remote_image_class.new(post, @dest_dir, @news_save, @firefox, @config)
    end

  end

  class CancellError < Exception; end
end




