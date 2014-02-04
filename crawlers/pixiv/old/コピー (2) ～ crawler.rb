# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'cgi'

require 'nokogiri'

require 'my/config'
require 'mtk/net/firefox'
require 'mtk/extensions/string'

require_relative 'constants'
require_relative 'picture'


module Pixiv

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler

    # pool: ThreadPool(mtk/concurrent/thread_pool)
    def initialize pool, keyword, opts = {}
      @pool = pool

      @keyword = keyword
      @s_mode = keyword.split(/\s|　/).size == 1 ? 's_tag_full' : 's_tag'
      @is_r18 = opts[:r18]
      @min_page = opts[:min_page] || 1
      @max_page = opts[:max_page] || 1
      @news_mode = opts[:news_mode]
      @db = opts[:db]

      @firefox = Mtk::Net::Firefox.new

      dir_prefix = @is_r18 ? "r18_" : ""
      @dest_dir = PIXIV_DIR.join "#{fix_basename(dir_prefix + @keyword)}"
      @dest_dir.mkdir unless @dest_dir.exist?

      if @is_r18
        # すでにr18なので振り分ける必要がない
        @r18_dir = nil
      elsif
        @r18_dir = @dest_dir.join("r18")
        @r18_dir.mkdir unless @r18_dir.exist?
      end

      NEWS_DIR.mkdir unless NEWS_DIR.exist?
    end

    def crawl
      (@min_page .. @max_page).each do |page|
        crawl_index page
      end
    rescue CancellError => e
      puts e.message
    end

    def get_document *args
      html = @firefox.get_html_as_utf8 *args
      doc = Nokogiri::HTML(html)
      return doc
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
      doc.css('li.image-item a.work').each do |anchor|
        child_uri = join_uri base_uri, anchor[:href]
        crawl_child(child_uri, base_uri)
      end

      # 次のページがなければ巡回を終了
      unless doc.css(%Q{ul.page-list li a}).any?{|a| a[:href] =~ /\bp=#{page+1}\b/}
        raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
      end
    end


    private
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


    def crawl_child base_uri, referer
      doc = get_document(base_uri, 'Referer' => referer)

      # 公開レベルなどの制限を受けたときは何もしない
      return if doc.at_css('span.error')

      #if html =~ %r{<div class="works_display"><a href="([^"]+)" target="_blank">}
      anchor = doc.at_css(%q{div.works_display a[target="_blank"]})
      if anchor
        works_uri = join_uri(base_uri, anchor[:href])
      else
          raise "not found work_display uri=#{base_uri}"
          #p "not found work_display uri=#{base_uri}"
          return
      end

      picture = PictureDb::Picture.new
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
      file = calc_image_path uri
      raise CancellError, "Cancell crawling, because found #{file} (news_mode)" if @news_mode && file.exist?

      @pool.push_task do
        begin
          do_download_image uri, *rest
        rescue => e
          puts "#{e.message} class=#{e.class} uri=#{uri} rest=#{rest}"
          pp e.backtrace
        end
      end
    end

    def do_download_image uri, referer, picture
      file = calc_image_path uri

      if @db
        @db.insert_file_path(picture, file)
      end
      return if file.exist?
      
puts uri 
      binary = @firefox.get_binary uri, 'Referer' => referer
      open(file, 'wb')do |f|
        f.write binary
      end

      FileUtils.link(file, NEWS_DIR) if @news_mode && !NEWS_DIR.join(file.basename).exist?
      

    ensure
      # r18のみのリンクを作成
      r18_file = @r18_dir.join(file.basename)
      FileUtils.link(file, r18_file) if @r18_dir && file.exist? && !r18_file.exist? && (picture.tags =~ /\bR-18\b/i)
    end


    def calc_image_path url
      basename = fix_basename(url.gsub(/\?.*/, '').split('/')[-1])
      file = @dest_dir.join(basename)
      return file
    end

    
    # ファイル名に使えない文字を取り除く
    def fix_basename basename
      result = basename.dup
      result.gsub!(%r{[\\/:*?"<>|]}, '')
      result.gsub!(/\s|　/, '_')
      return result
    end

    def join_uri *args
      return URI.join(*args).to_s
    end
  end

  class CancellError < StandardError; end
  class OutOfIndexError < CancellError; end
end


