# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'cgi'

require 'my/config'
require 'mtk/net/firefox'
require 'mtk/extensions/string'
#require 'mtk/net/uri_getter'

require_relative 'constants'
require_relative 'picture'


module Pixiv

  # オプション引数の説明
  #   news_modeが真のとき
  #     1.保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #     2.新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler

    #class Picture < Struct.new(
    #    :illust_id,
    #    :tags,
    #    :score_count)
    #end

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

    def crawl_index page
      puts "index: page=#{page} keyword=#{@keyword}"

      base_uri = index_uri page

      html = @firefox.get_html_as_utf8 base_uri

      # もう画像がない
      if html =~ %r{<div class="_no-item">見つかりませんでした</div>}
        raise OutOfIndexError, "Out of index page: page=#{page} keyword=#{@keyword}"
      end

      # 子のページを探す
      pattern = %r{<li class="image-item"><a href="([^"]+)" class="work">}
      #html.scan(pattern).sort.reverse.each do |s|
      html.scan(pattern) do |s|
        path = CGI.unescapeHTML(s[0])
        child_uri = join_uri base_uri, path
        crawl_child(child_uri)
      end

      # 次のページがなければ巡回を終了
      unless html =~ %r{<a href="[^"]*p=(#{page+1})[^"]*">\1</a>}
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


    def crawl_child base_uri
      html = @firefox.get_html_as_utf8 base_uri

      if html =~ %r{<span class="error">.*該当作品の公開レベルにより閲覧できません。.*</span>}
        return
      end

      if html =~ %r{<div class="works_display"><a href="([^"]+)" target="_blank">}
        path = CGI.unescapeHTML($1)
        works_uri = join_uri base_uri, path
      else
          raise "not found work_display uri=#{base_uri}"
      end

      #picture = Picture.new
      picture = PictureDb::Picture.new
      picture.illust_id = works_uri.match(/illust_id=(\d+)/)[1]

      picture.tags = scan_tags(html).join(" ")
      picture.score_count = html.match(%r{<dd class="score-count">(\d+)</dd>})[1].to_i

      @db.insert_picture picture if @db

      crawl_works(works_uri, base_uri, picture)
    end


    # childページからtagを取得
    def scan_tags html
     # pattern = Regexp.new(<<-EOS.split("\n").map(&:strip).join)
     #   <li class="tag">
     #     (?:<a href="[^"]+" class="portal">[^>]*</a><span class="self-tag">[^>]*</span>)?
     #     <a href="[^"]+" class="text">([^>]+)</a>
     #     (?:<a href="[^"]+" target="_blank" class="icon-pixpedia ui-tooltip" data-tooltip="[^"]*"></a>)?
     #   </li>
     # EOS
      
      pattern = Regexp.new(<<-EOS.split("\n").map(&:strip).join)
        <li class="tag">
          .*?
          <a href="[^"]+" class="text">([^>]+)</a>
          .*?
        </li>
      EOS


      return html.scan(pattern).map(&:first)
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
      html = @firefox.get_html_as_utf8 base_uri, 'Referer' => referer
      pattern = %r{<body><img src="([^"]+)"}

      html.scan(pattern) do |s|
        path = s [0]
        #p base_uri, path
        image_uri = join_uri base_uri, path 
        #p image_uri 
        download_image image_uri, base_uri, picture
      end
    end

    def crawl_manga base_uri, referer, picture
      html = @firefox.get_html_as_utf8 base_uri, 'Referer' => referer
      #pattern = %r{data-filter="manga-image" data-src="([^"]+)"}
      pattern = %r{<a href="([^"]+)" target="_blank" class="full-size-container ui-tooltip" data-tooltip="(?:[^"]+)">}
      html.scan(pattern) do |s|
        path = s [0]
        image_uri = join_uri base_uri, path 
        crawl_big image_uri, base_uri, picture
        #download_image image_uri, base_uri, picture
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
      #basename = url.gsub(/\?.*/, '').split('/')[-1]
      file = @dest_dir.join(basename)
      return file
    end


    def get_binary_with_firefox uri, *args
      options = {"Cookie" => @cookie}
      opts = args[-1].is_a?(Hash) ? args.pop : {}
      options.merge! opts
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


