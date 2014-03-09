# vim:set fileencoding=utf-8:

require 'pathname'
require 'fileutils'
require 'pp'
require 'uri'
require 'cgi'

require 'parallel'
require 'my/config'
require 'mtk/net/firefox'
require 'mtk/net/uri_getter'

require_relative '../util'

class String
  # ヒアドキュメントのインデント対応用
  def ~
    margin = scan(/^ +/).map(&:size).min
    gsub(/^ {#{margin}}/, '')
  end
end

module Yandere

  YANDERE_DIR = Crawlers::Config::app_dir + 'yande.re'
  NEWS_DIR = YANDERE_DIR + "news"

  # オプション引数の説明
  #   news_onlyが真のとき
  #     ・保存する対象の画像がすでにあった場合、以降の巡回をすべて中止します
  #   news_saveが真のとき
  #     ・新規に保存した画像へのハードリンクをnewsディレクトリに追加します
  class Crawler
    include Crawlers::Util

    THREAD_COUNT_DOWNLOAD_IMAGES = 5

    # pool: ThreadPool(mtk/concurrent/thread_pool)
    def initialize pool, keyword, opts = {}
      @pool = pool

      @keyword = keyword
      @min_page = opts[:min_page] || 1
      @max_page = opts[:max_page] || 1
      #@news_mode = opts[:news_mode]
      @news_only = opts[:news_only]
      @news_save = opts[:news_save]



      @firefox = Mtk::Net::Firefox.new

      @dest_dir = YANDERE_DIR.join "#{fix_basename(@keyword)}"
      @dest_dir.mkdir unless @dest_dir.exist?

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
p base_uri
      html = @firefox.get_html_as_utf8(base_uri)

      # もう画像がない
      if html =~ %r{Nobody here but us chickens!}
        raise OutOfIndexError, "Out of index page: page=#{page} keyword=#{@keyword}"
      end

      # 子のページを探す
      pattern = ~<<-'EOS'
        <span class="plid">#pl https://yande.re/post/show/(\d+)</span></a></div>
        <a class="directlink largeimg" href="([^"]+)">
      EOS
      pattern.gsub!(/\n/, '')
      pattern = Regexp.new pattern

      #html.scan(pattern).sort.reverse.each do |s|
      remote_images = html.scan(pattern).map{|s|
        id = s[0]
        path = CGI.unescapeHTML(s[1])
        ext = path.match(/\.[^.]+$/)[0]
        dest_file = @dest_dir.join("#{id}#{ext}")

        image_uri = join_uri base_uri, path
        {image_uri: image_uri, dest_file: dest_file}
      }

      Parallel.each(remote_images, in_threads: THREAD_COUNT_DOWNLOAD_IMAGES) {|h| download_image(h[:image_uri], base_uri, h[:dest_file])}

      # 次のページがなければ巡回を終了
      unless html =~ %r{<link href="[^"]+" rel="next" title="Next Page" />}
        raise CancellError, "Reach end of index page: page=#{page} keyword=#{@keyword}"
      end
    end


    private
    def index_uri page
      h = {
        page: page,
        tags: @keyword
      }
      query = URI.encode_www_form h
      return"https://yande.re/post?#{query}"
    end


    def download_image uri, referer, dest_file
      raise CancellError, "Cancell crawling, because found #{dest_file} (news_only)" if @news_only && dest_file.exist?

      #@pool.push_task do
        begin
          do_download_image uri, referer, dest_file
        rescue => e
          puts e
          pp e.backtrace
        end
        #end
    end

    def do_download_image uri, referer, dest_file
      return if dest_file.exist?
      
puts uri 
      binary = @firefox.get_binary uri, 'Referer' => referer
      open(dest_file, 'wb')do |f|
        f.write binary
      end

      FileUtils.link(dest_file, NEWS_DIR) if @news_save && !NEWS_DIR.join(dest_file.basename).exist?
    end


    def join_uri *args
      return URI.join(*args).to_s
    end
  end

  class CancellError < StandardError; end
  class OutOfIndexError < CancellError; end
end


