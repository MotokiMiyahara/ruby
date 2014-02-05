# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'timeout'

require 'nokogiri'

require 'my/config'
require 'mtk/net/firefox'
require 'mtk/concurrent/thread_pool'
require 'mtk/extensions/string'

require_relative 'constants'
require_relative 'picture'
require_relative '../util'
require_relative '../errors'
require_relative 'config'
require_relative 'remote_image'
require_relative 'search_file_finder'

require 'net/http'
require 'parallel'

module Pixiv

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class ParallelCrawler
    include Crawlers::Util

    VERBOSE = false
    #VERBOSE = true
    THREAD_COUNT_GET_IMAGE_URLS = 3
    THREAD_COUNT_DOWNLOAD_IMAGES = 3

    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1, priority: 1)
    #@pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, priority: 2)
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, priority: 3)
    class << self
      attr_reader :pool_crawl, :pool_child, :pool_download
      def join
        #pool_crawl.join
        # pool_child.join
        #  pool_download.join
      end
    end
    
    def initialize keyword, options = {}
      default_options = {
        r18: false,
        min_page: 1,
        max_page: 1,
        news_only: false,
        news_save: true,
        db: nil,
        dir: "",
      }
      opts = default_options.merge(options)

      @keyword = keyword
      @s_mode = keyword.split(/\s|　/).size == 1 ? 's_tag_full' : 's_tag'

      @is_r18 = opts[:r18]
      @min_page = opts[:min_page]
      @max_page = opts[:max_page]
      @news_only = opts[:news_only]
      @news_save = opts[:news_save]
      @db = opts[:db]

      @firefox = Mtk::Net::Firefox.new

      @dest_dir = make_dest_dir(keyword, opts[:dir], @is_r18)
      @search_file_finder = SearchFileFinder.new(@dest_dir)

      if @is_r18
        # すでにr18なので振り分ける必要がない
        @r18_dir = nil
      elsif
        @r18_dir = @dest_dir.join("r18")
        @r18_dir.mkdir unless @r18_dir.exist?
      end

      NEWS_DIR.mkdir unless NEWS_DIR.exist?
    end



    public


    def crawl
      #self.class.pool_crawl.push_task do
      #Parallel.each do
      #  do_crawl
      #end

      do_crawl
    end


    private
    def do_crawl
      (@min_page .. @max_page).each do |page|
        crawl_index(page)
      end
    rescue CancellError => e
      log e.message
    end

    def ident_message
      return "keyword='#{@keyword}'"
    end

    def crawl_index page
      #log "index: page=#{page} keyword=#{@keyword}"
      log "index: page=#{page} #{ident_message}"
      base_uri = index_uri(page)
      doc = get_document(base_uri)

      # もう画像がない
      if doc.at_css('div._no-item')
        raise OutOfIndexError, "Out of index page: page=#{page} keyword=#{@keyword}"
      end

      anchors = doc.css('li.image-item a.work')
      child_uris = anchors.map{|anchor| child_uri = join_uri(base_uri, anchor[:href])}
      
      # ネットワーク接続無しでダウンロード済みのファイルを取り除く
      #existing_child_uris, new_child_uris = child_uris.partition{|uri| @search_file_finder.find_by_uri(uri)} 
      new_child_uris = child_uris.reject{|uri| @search_file_finder.find_by_uri(uri)} 
      images = fetch_remote_images(base_uri, new_child_uris)

      # 実際に接続した結果を利用してダウンロード済みのファイルを取り除く
      new_images = images.reject{|img| img.search_file.exist?}
      download_images(new_images)

      if @news_only && new_images.empty?
        raise CancellError, "Cancell crawling, because not found new images in {page: #{page}, keyword: '#{@keyword}'} (news_only)" 
      end

      # ページ内にダウンロード済みの画像があれば巡回停止
      #if @news_only
      #  unless existing_child_uris.empty?
      #    raise CancellError, "Cancell crawling, because found #{@search_file_finder.find_by_uri(existing_child_uris[0])} (news_only)"
      #  end
      #  raise CancellError, "Cancell crawling, because found #{existing_images[0].search_file} (news_only)" unless existing_images.empty?
      #end

      # 次のページがなければ巡回を終了
      unless doc.css(%Q{ul.page-list li a}).any?{|a| a[:href] =~ /\bp=#{page+1}\b/}
        raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
      end
    end

    #def crawl_index page
    #  #log "index: page=#{page} keyword=#{@keyword}"
    #  log "index: page=#{page} #{ident_message}"
    #  base_uri = index_uri(page)
    #  doc = get_document(base_uri)

    #  # もう画像がない
    #  if doc.at_css('div._no-item')
    #    raise OutOfIndexError, "Out of index page: page=#{page} keyword=#{@keyword}"
    #  end

    #  anchors = doc.css('li.image-item a.work')
    #  child_uris = anchors.map{|anchor| child_uri = join_uri(base_uri, anchor[:href])}
    #  
    #  # ネットワーク接続無しでダウンロード済みのファイルを取り除く
    #  existing_child_uris, new_child_uris = child_uris.partition{|uri| @search_file_finder.find_by_uri(uri)} 
    #  images = fetch_remote_images(base_uri, new_child_uris)

    #  # 実際に接続した結果を利用してダウンロード済みのファイルを取り除く
    #  existing_images, new_images,  = images.partition{|img| img.search_file.exist?}
    #  download_images(new_images)

    #  # ページ内にダウンロード済みの画像があれば巡回停止
    #  if @news_only
    #    unless existing_child_uris.empty?
    #      raise CancellError, "Cancell crawling, because found #{@search_file_finder.find_by_uri(existing_child_uris[0])} (news_only)"
    #    end
    #    raise CancellError, "Cancell crawling, because found #{existing_images[0].search_file} (news_only)" unless existing_images.empty?
    #  end

    #  # 次のページがなければ巡回を終了
    #  unless doc.css(%Q{ul.page-list li a}).any?{|a| a[:href] =~ /\bp=#{page+1}\b/}
    #    raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
    #  end
    #end

    def index_uri(page)
      h = {
        s_mode: @s_mode,
        r18: @is_r18 ? 1 : 0,
        order: :date_d,
        p: page,
        word: @keyword
      }
      query = URI.encode_www_form h
      return"http://www.pixiv.net/search.php?#{query}"
    end

    def fetch_remote_images(base_uri, child_uris)
      remote_images = Parallel.map(child_uris, in_threads: THREAD_COUNT_GET_IMAGE_URLS) {|child_uri|
        unless child_uri =~ /illust_id=\d+/
          log "skip because illust_id not found: uri=#{child_uri} base=#{base_uri} keyword=#{@keyword}"
          next []
        end
        crawl_child(child_uri, base_uri)
      }.flatten
      return remote_images
    end

    #def get_image_uris(base_uri, anchors)
    #  image_uris = Parallel.map(anchors, in_threads: THREAD_COUNT_GET_IMAGE_URLS) {|anchor|
    #    child_uri = join_uri(base_uri, anchor[:href])
    #    unless child_uri =~ /illust_id=\d+/
    #      log "skip because illust_id not found: page=#{child_uri} keyword=#{@keyword}"
    #      next
    #    end
    #    crawl_child(child_uri, base_uri)
    #  }.flatten
    #  return image_uris
    #end

    def crawl_child(*args)
      image_urls = retry_fetch do
        do_crawl_child(*args)
      end
      return image_urls
    rescue Crawlers::DataSourceError => e
      log "give up doing crawl_child because #{e}"
      return []
    end

    def do_crawl_child(base_uri, referer)
      doc = get_document(base_uri, 'Referer' => referer)

      # 公開レベルなどの制限を受けたときは何もしない
      return [] if doc.at_css('span.error')

      anchor = doc.at_css(%q{div.works_display a[target="_blank"]})
      if anchor
        works_uri = join_uri(base_uri, anchor[:href])
      else
        raise Crawlers::DataSourceError, "not found work_display uri=#{base_uri}}"
      end

      if @db
        picture = PictureDb::Picture.new
        else
        picture = PictureDb::DummyPicture.new
      end

      picture.illust_id = works_uri.match(/illust_id=(\d+)/)[1]
      picture.tags = scan_tags(doc).join(" ")
      picture.score_count = (doc.at_css('dd.score-count').text.strip =~ /\d+/) ? $&.to_i : 0

      @db.insert_picture picture if @db

      return crawl_works(works_uri, base_uri, picture)
    end


    # childページからtagを取得
    def scan_tags doc
      return doc.css('.tags-container .tags .tag a.text').map(&:text).map(&:strip)
    end
    
    # @return [Array<Remoteimage>]
    def crawl_works(base_uri, referer, picture)
      if base_uri =~ /mode=big/
        return crawl_big(base_uri, referer, picture)
      elsif base_uri =~ /mode=manga/
        return crawl_manga(base_uri, referer, picture)
      else
        raise "unknown pattern: #{base_uri}"
      end
    end

    # @return [Array<Remoteimage>]
    def crawl_big(base_uri, referer, picture)
      doc = get_document(base_uri, 'Referer' => referer)
      img = doc.at_css('img')
      return unless img

      image_uri = join_uri(base_uri, img[:src])

      return [RemoteImage.new(@firefox, @news_save, @dest_dir, @r18_dir, image_uri, base_uri, picture)]
    end

    # @return [Array<Remoteimage>]
    def crawl_manga(base_uri, referer, picture)
      doc = get_document(base_uri, 'Referer' => referer)

      return doc.css('a.full-size-container').flat_map { |anchor|
        image_uri = join_uri base_uri, anchor[:href]
        crawl_big(image_uri, base_uri, picture)
      }
    end

    def download_images(remote_images)
      Parallel.map(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|image|
        @db.insert_file_path(image.picture, image.regular_file) if @db
        image.download
      }
    end

    def make_dest_dir(keyword, parent_dir, is_r18)
      parent_dir = "" unless parent_dir
      parent_dir = parent_dir.split('/').map{|s| fix_basename(s)}.join('/')

      dir_prefix = is_r18 ? "r18_" : ""
      dest_dir = SEARCH_DIR.join(parent_dir, "#{fix_basename(dir_prefix + keyword)}")
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
  class OutOfIndexError < CancellError; end
end


def crawl
  # 巡回設定
  keywords = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    艦これ
  EOS

  keywords.each do |keyword|
    pp keyword
    Pixiv::ParallelCrawler.new(
      keyword,
      min_page: 960,
      max_page: 5001,
      r18: false,
      #dir: '東方Project',
      news_only: false,
      news_save: false,
      db: nil
    ).crawl
  end
end

if $0 == __FILE__ 
  tlog('start')
  crawl
  tlog('end')
end

