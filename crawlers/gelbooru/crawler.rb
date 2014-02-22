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
      #start_index_uri = "http://gelbooru.com/index.php?page=post&s=list&tags=#{@keyword}"
      start_index_uri = "http://gelbooru.com/index.php?page=post&s=list&tags=#{URI.encode_www_form_component(@keyword)}"
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
      remote_images = doc.css('.thumb').map{|thumb|
        img = thumb.at_css('img')
        thumbnail_uri = img['src']

        anchor = thumb.at_css('a')
        display_uri = join_uri(index_uri, anchor['href'])

        next RemoteImage.new(thumbnail_uri, display_uri, @dest_dir, @news_save, @firefox)
      }

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



if $0 == __FILE__ 
  tlog('start')
  Gelbooru::Crawler.new(
    'nude_filter',
    #'null_(nyanpyoun)',
    news_only: true,
  ).crawl
  tlog('end')
end

