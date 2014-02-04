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
require_relative 'config'

require 'net/http'

raise
module Pixiv

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler
    include Crawlers::Util

    #VERBOSE = true

    # class instance variable
    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 5)
    #@pool_child     = Mtk::Concurrent::HalfPool.new(max_worker_count: 20) 
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 50)

    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 2)
    #@pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 5) 
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 10)

    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1)
    #@pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1) 
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 3)

    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1, size: :infinity)
    #@pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1, size: :infinity) 
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, size: :infinity)

    #@pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1, size: :infinity)
    #@pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, size: :infinity) 
    #@pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, size: :infinity)

    @pool_crawl    = Mtk::Concurrent::HalfPool.new(max_worker_count: 1, priority: 1)
    @pool_child    = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, priority: 2)
    @pool_download = Mtk::Concurrent::HalfPool.new(max_worker_count: 3, priority: 3)
    class << self
      attr_reader :pool_crawl, :pool_child, :pool_download
      def join
          pool_crawl.join
          pool_child.join
          pool_download.join
      end
    end
    

    # pool: ThreadPool(mtk/concurrent/thread_pool)
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
      #@news_mode = opts[:news_mode]
      @news_only = opts[:news_only]
      @news_save = opts[:news_save]
      @db = opts[:db]

      @firefox = Mtk::Net::Firefox.new

      @dest_dir = make_dest_dir(keyword, opts[:dir], @is_r18)

      if @is_r18
        # すでにr18なので振り分ける必要がない
        @r18_dir = nil
      elsif
        @r18_dir = @dest_dir.join("r18")
        @r18_dir.mkdir unless @r18_dir.exist?
      end

      NEWS_DIR.mkdir unless NEWS_DIR.exist?

      # news_modeのときは、CancellErrorが発生するため別スレッドを使えない
      @pool_child = @news_only ? Mtk::Concurrent::HalfPool::DUMMY : self.class.pool_child
    end

    public
    def crawl
      self.class.pool_crawl.push_task do
        do_crawl
      end
    end


    private
    def do_crawl
      (@min_page .. @max_page).each do |page|
        crawl_index page
      end
    rescue CancellError => e
      puts e.message
    end

    def get_document(uri, *rest)
      retry_fetch(message: uri) do
        html = @firefox.get_html_as_utf8(uri, *rest)
        doc = Nokogiri::HTML(html)
        return doc
      end
    end

    def crawl_index page
      puts "index: page=#{page} keyword=#{@keyword}"
      base_uri = index_uri page
      doc = get_document(base_uri)

      # もう画像がない
      if doc.at_css('div._no-item')
        raise OutOfIndexError, "Out of index page: page=#{page} keyword=#{@keyword}"
      end

      # 子のページを探す
      #ths = []
      doc.css('li.image-item a.work').each do |anchor|
        child_uri =(join_uri base_uri, anchor[:href])
        unless child_uri =~ /illust_id=\d+/
          puts "skip because illust_id not found: page=#{page} keyword=#{@keyword}"
          next
        end
        @pool_child.push_task do
          crawl_child(child_uri, base_uri)
        end
      end

      # 次のページがなければ巡回を終了
      unless doc.css(%Q{ul.page-list li a}).any?{|a| a[:href] =~ /\bp=#{page+1}\b/}
        raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
      end
    end


    def index_uri page
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

    def crawl_child *args
      retry_fetch do
        do_crawl_child *args
      end
    rescue RetryableError => e
      puts "give up doing crawl_child because #{e}"
    end

    def do_crawl_child base_uri, referer
      doc = get_document(base_uri, 'Referer' => referer)

      # 公開レベルなどの制限を受けたときは何もしない
      return if doc.at_css('span.error')

      #if html =~ %r{<div class="works_display"><a href="([^"]+)" target="_blank">}
      anchor = doc.at_css(%q{div.works_display a[target="_blank"]})
      if anchor
        works_uri = join_uri(base_uri, anchor[:href])
      else
          #File.open('a.txt', 'w:utf-8'){|f| f.puts doc}
          #raise StandardError
          raise RetryableError, "not found work_display uri=#{base_uri}}"
          #raise RetryableError, "not found work_display uri=#{base_uri} #{doc}"
          #raise "not found work_display uri=#{base_uri}"
          #p "not found work_display uri=#{base_uri}"
          return
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

      crawl_works(works_uri, base_uri, picture)
    end


    # childページからtagを取得
    def scan_tags doc
      return doc.css('.tags-container .tags .tag a.text').map(&:text).map(&:strip)
    end
    
    def crawl_works base_uri, referer, picture
      if base_uri =~ /mode=big/
        crawl_big base_uri, referer, picture
      elsif base_uri =~ /mode=manga/
        crawl_manga base_uri, referer, picture
      else
        raise "unknown pattern: #{base_uri}"
      end
    end

    def crawl_big base_uri, referer, picture
      doc = get_document(base_uri, 'Referer' => referer)
      img = doc.at_css('img')
      return unless img

      image_uri = join_uri base_uri, img[:src]
      download_image image_uri, base_uri, picture
    end

    def crawl_manga base_uri, referer, picture
      doc = get_document(base_uri, 'Referer' => referer)

      doc.css('a.full-size-container').each do |anchor|
        image_uri = join_uri base_uri, anchor[:href]
        crawl_big image_uri, base_uri, picture
      end
    end

    def download_image uri, *rest
      search_file = calc_search_image_pathname(uri)
      raise CancellError, "Cancell crawling, because found #{search_file} (news_only)" if @news_only && search_file.exist?

      self.class.pool_download.push_task do
        begin
          do_download_image uri, *rest
        rescue => e
          begin
            puts "#{e.message} class=#{e.class} uri=#{uri} rest=#{rest}"
            pp e.backtrace
          rescue
            raise e
          end
        end
      end
    end

    def do_download_image(uri, referer, picture)
      regular_file = calc_regular_image_pathname(uri)

      if @db
        @db.insert_file_path(picture, regular_file)
      end

      unless regular_file.exist?
        fetch_image(uri, referer, regular_file)
        if @news_save
          # newsフォルダにリンクを作成
          news_file = calc_news_image_pathname(uri)
          make_link_quietly(regular_file, news_file)
          #FileUtils.link(file, NEWS_DIR) if @news_save && !NEWS_DIR.join(file.basename).exist?
        end
      end


      # キーワード毎のフォルダにリンクを作成
      search_file = calc_search_image_pathname(uri)
      make_link_quietly(regular_file, search_file)


      # r18のみのリンクを作成
      if @r18_dir && (picture.tags =~ /\bR-18\b/i)
        r18_file = @r18_dir.join(regular_file.basename)
        make_link_quietly(regular_file, r18_file)
        #FileUtils.link(file, r18_file) if @r18_dir && regular_file.exist? && !r18_file.exist? && (picture.tags =~ /\bR-18\b/i)
      end
    end

    def fetch_image(uri, referer, file)
puts uri 
        binary = retry_fetch(message: uri) {
          @firefox.get_binary uri, 'Referer' => referer
        }
        write_binary_quietly(file, binary)
    end

    def calc_regular_image_pathname(uri)
      Pixiv::Config.regular_image_pathname_from_uri(uri)
      #calc_pathname_in_dir(uri, ALL_IMAGE_DIR)
    end

    def calc_search_image_pathname(uri)
      calc_pathname_in_dir(uri, @dest_dir)
    end

    def calc_news_image_pathname(uri)
      calc_pathname_in_dir(uri, NEWS_DIR)
    end

    def calc_pathname_in_dir(uri, dir)
      basename = fix_basename(uri.gsub(/\?.*/, '').split('/')[-1])
      file = dir.join(basename)
      return file
    end

    def join_uri *args
      return URI.join(*args).to_s
    end

    def make_dest_dir(keyword, parent_dir, is_r18)
      parent_dir = "" unless parent_dir
      parent_dir = parent_dir.split('/').map{|s| fix_basename(s)}.join('/')

      dir_prefix = is_r18 ? "r18_" : ""
      dest_dir = SEARCH_DIR.join(parent_dir, "#{fix_basename(dir_prefix + keyword)}")
      dest_dir.mkpath unless dest_dir.exist?
      return dest_dir
    end

    # ファイルがなければ作成しブロックを実行する, ファイルがあれば何もしない
    def write_binary_quietly(file, binary)
      open(file, File::BINARY | File::WRONLY | File::CREAT | File::EXCL) do |f|
        f.write(binary)
      end
    rescue Errno::EEXIST => e
      pp e #if VERBOSE
    end

    def make_link_quietly(old, new)
      #FileUtils.link(
      #  old, new,
      #  force: true,
      #  #verbose: true,
      #)
      FileUtils.ln_sf(old, new)
    end


    def retry_fetch(opt={}, &block)
      raise 'block is required ' unless block
      initial_sec = 1
      try_max_limit = 10
      #try_max_limit = 5

      try_count = 1
      begin
        return block.call
      rescue  Net::HTTPBadResponse, SocketError, OpenURI::HTTPError, Timeout::Error, EOFError, RetryableError => e
        raise e unless try_count < try_max_limit
        puts "retry try_count=#{try_count} class=#{e.class} e=#{e} mes='#{opt[:message]}'"

        sleep_sec = initial_sec * (2 ** (try_count - 1))
        puts "sleep #{sleep_sec} sec"
        sleep(sleep_sec)

        try_count += 1
        retry
      end
    end

  end

  class CancellError < StandardError; end
  class OutOfIndexError < CancellError; end
  class OutOfIndexError < CancellError; end

  class RetryableError < StandardError; end
end


