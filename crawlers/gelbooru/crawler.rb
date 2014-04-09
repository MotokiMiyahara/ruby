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

require_relative '../util'
require_relative '../errors'
require_relative 'config'
require_relative 'remote_image'


module Gelbooru

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler
    include Crawlers::Util

    VERBOSE = false
    #THREAD_COUNT_DOWNLOAD_IMAGES = 200
    THREAD_COUNT_DOWNLOAD_IMAGES = 20

    def initialize(
          keyword,
          news_only: false,
          news_save: true,
          dest_dir: nil,
          noop:     true,
          image_count_per_page: :auto # max 200(Gelbooru APIの仕様上)
        )


      @keyword = keyword
      @news_only = news_only
      @news_save = news_save
      @dest_dir = calc_dest_dir(keyword, dest_dir)
      @noop = noop

      @image_count_per_page = calc_image_count_per_page(image_count_per_page)

      @firefox = Mtk::Net::Firefox.new
      @dest_dir.mkpath unless @noop || @dest_dir.exist?
    end



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
      max_page = calc_max_page

      (0..max_page).each do |page|
        crawl_page(page)
      end
    rescue CancellError => e
      log e.message
    end

    def crawl_page(page)
      log "index: page=#{page} #{ident_message}"

      q = {
        page:  'dapi',
        s:     'post',
        q:     'index',
        tags:  @keyword,
        limit: @image_count_per_page,
        pid:   page,
      }

      query = URI.encode_www_form(q)
      uri = "http://gelbooru.com/index.php?#{query}"
      doc = get_document(uri)

      posts = doc.css('posts post')
      remote_images = posts.map{|post| RemoteImage.new(post[:id], post[:file_url], @dest_dir, @news_save, @firefox)}

      remote_images.reject!{|image| image.search_file.exist?}
      Parallel.each(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|image| image.download}

      if @news_only && remote_images.empty?
        raise CancellError, "Cancell crawling, because not found new images in {page: #{page}, keyword: '#{@keyword}'} (news_only)" 
      end
    end

    def calc_max_page
      image_count = fetch_image_count
      page_count = image_count.quo(@image_count_per_page).ceil
      max_page = page_count - 1
      return max_page
    end

    def fetch_image_count
      q = {
        page:  'dapi',
        s:     'post',
        q:     'index',
        tags:  @keyword,
        limit: 0,
        pid:   0,
      }

      query = URI.encode_www_form(q)
      uri = "http://gelbooru.com/index.php?#{query}"
      log "api-uri='#{uri}'"

      doc = get_document(uri)
      posts = doc.at_css('posts')
      return posts[:count].to_i
    end

    def calc_dest_dir(keyword, rerative_dest_dir)
      rerative_dest_dir ||= fix_basename(keyword)
      rerative_dest_dir = Pathname(rerative_dest_dir)
      dest_dir = SEARCH_DIR + rerative_dest_dir
      return dest_dir
    end

    # @return [Integer]
    def calc_image_count_per_page(var)
      case var
      when :auto
        @dest_dir.exist? ? 30 : 200
      when Integer
        var
      else
        raise ArgumentError, "image_count_per_page is 'auto' or number"
      end
    end

    def get_document(uri, *rest)
      retry_fetch(message: uri) do
        html = @firefox.get_html_as_utf8(uri, *rest)
        #doc = Nokogiri::HTML(html)
        doc = Nokogiri::XML(html)
        return doc
      end
    end

    def ident_message
      return "keyword='#{@keyword}'"
    end
  end

  class CancellError < Exception; end
  #class OutOfIndexError < CancellError; end
end


def crawl(keyword)
  Gelbooru::Crawler.new(
    keyword,
    news_only: true
  ).crawl
end

KEYWORDS = [
  'nude_filter',
  'smile nipples pussy -amputee -nude_filter',
]

if $0 == __FILE__ 
  tlog('start')
  KEYWORDS.each do |keyword|
    crawl(keyword)
  end
  tlog('end')
end

