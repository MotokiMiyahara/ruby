# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'timeout'

require 'nokogiri'

require 'my/config'
require 'mtk/util'
require 'mtk/net/firefox'
#require 'mtk/concurrent/thread_pool'
#require 'mtk/extensions/string'

#require_relative 'constants'
#require_relative 'picture'
require_relative '../util'
require_relative '../errors'
require_relative 'config'
#require_relative 'remote_image'
#require_relative 'search_file_finder'

require 'net/http'
require 'parallel'

module Gelbooru

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler
    include Crawlers::Util

    VERBOSE = false
    THREAD_COUNT_DOWNLOAD_IMAGES = 3

    def initialize(
          keyword,
          news_only: false,
          news_save: true
        )

      @keyword = keyword
      @news_only = news_only
      @news_save = news_save

      @firefox = Mtk::Net::Firefox.new
      @dest_dir = make_dest_dir(keyword)
    end



    public
    def crawl
      start_index_uri = "http://gelbooru.com/index.php?page=post&s=list&tags=#{@keyword}"
      crawl_index(start_index_uri, 1)
    rescue CancellError => e
      log e.message
    end


    private
    def ident_message
      return "keyword='#{@keyword}'"
    end

    def crawl_index(index_uri, page)
      log "index: page=#{page} #{ident_message}"

      doc = get_document(index_uri)
      thumbnail_uris = doc.css('.thumb img').map{|img| img['src']}
      remote_images = thumbnail_uris.map{|uri| RemoteImage.new(uri, @dest_dir, @news_save, @firefox)}
      remote_images.reject!{|image| image.search_file.exist?}
      Parallel.each(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|image| image.download}

      if @news_only && remote_images.empty?
        raise CancellError, "Cancell crawling, because not found new images in {page: #{page}, keyword: '#{@keyword}'} (news_only)" 
      end

      next_anchor = doc.at_css('.pagination a[alt="next"]')
      if next_anchor
        next_uri = join_uri(index_uri, next_anchor['href'])
        crawl_index(next_uri, page + 1)
      else
        # 次のページがなければ巡回を終了
        raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
      end

    end

    def make_dest_dir(keyword)
      parent_dir = "" #unless parent_dir
      parent_dir = parent_dir.split('/').map{|s| fix_basename(s)}.join('/')

      dest_dir = SEARCH_DIR.join(parent_dir, fix_basename(keyword))
      dest_dir.mkpath unless dest_dir.exist?
      return dest_dir
    end

    def get_document(uri, *rest)
      retry_fetch(message: uri) do
        html = @firefox.get_html_as_utf8(uri, *rest)
        doc = Nokogiri::HTML(html)
        return doc
      end
    end
  end

  class CancellError < Exception; end
  #class OutOfIndexError < CancellError; end
end

module Gelbooru
  class Crawler
    class RemoteImage
      include Crawlers::Util

      PREFIX = 'gelbooru_'

      attr_reader :search_file
      def initialize(thumbnail_uri, dest_dir, news_save, fire_fox)
        @uri = thumbnail_uri.sub(%r{thumbnails}, 'images').sub(%r{thumbnail_}, '')
        @dest_dir = dest_dir
        @news_save = news_save
        @firefox = fire_fox

        @regular_file = calc_regular_image_pathname
        @search_file = calc_search_image_pathname
        @news_file = calc_news_image_pathname
      end

      def calc_regular_image_pathname
        uri = URI(@uri)
        number = uri.path.match(%r{/[^/]+/(\d+)/}).to_a[1]
        dir = ALL_IMAGE_DIR.join(number)
        dir.mkpath unless dir.exist?
        return calc_pathname_in_dir(dir)
      end
      private :calc_regular_image_pathname

      def calc_search_image_pathname
        return calc_pathname_in_dir(@dest_dir)
      end
      private :calc_search_image_pathname

      def calc_news_image_pathname
        return calc_pathname_in_dir(NEWS_DIR)
      end
      private :calc_news_image_pathname

      def calc_pathname_in_dir(dir)
        uri = URI(@uri)
        basename = uri.path.split('/')[-1]
        file = dir.join(PREFIX + basename)
        return file
      end
      private :calc_pathname_in_dir

      def download
        download_image(@uri)
      end

      def download_image(uri)
        if @search_file.exist?
          log "found search_file #{@search_file}. abort download."
          return
        end

        begin
          do_download_image(uri)
        rescue => e
          begin
            log "#{e.message} class=#{e.class} uri=#{uri}"
            pp e.backtrace
          end
        end
      end

      def do_download_image(uri)
        unless @regular_file.exist?
          fetch_image(uri, @regular_file)
          if @news_save
            # newsフォルダにリンクを作成
            make_link_quietly(@regular_file, @news_file)
          end
        end

        # キーワード毎のフォルダにリンクを作成
        make_link_quietly(@regular_file, @search_file)
      end

      def fetch_image(uri, file)
        log uri 
        binary = retry_fetch(message: uri) {
          #@firefox.get_binary(uri, 'Referer' => referer)
          @firefox.get_binary(uri)
        }
        write_binary_quietly(file, binary)
      end

      def write_binary_quietly(file, binary)
        # ファイルがなければ作成しブロックを実行する, ファイルがあれば何もしない
        open(file, File::BINARY | File::WRONLY | File::CREAT | File::EXCL) do |f|
          f.write(binary)
        end
      rescue Errno::EEXIST => e
        pp e #if VERBOSE
      end

      def make_link_quietly(old, new)
        FileUtils.ln_sf(old, new, verbose: VERBOSE)
      end
    end
  end
end


if $0 == __FILE__ 
  tlog('start')
  Gelbooru::Crawler.new(
    'nude_filter',
    #news_only: true,
  ).crawl
  tlog('end')
end

