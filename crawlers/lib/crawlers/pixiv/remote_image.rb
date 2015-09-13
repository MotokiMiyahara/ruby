# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pp'
require 'fileutils'
require_relative '../util'
require_relative '../errors'

module Pixiv
  class ParallelCrawler
    class RemoteImage
      include Crawlers::Util
      attr_reader(
        :regular_file,
        :search_file,
        :picture
      )

      def initialize(firefox, news_save, dest_dir, r18_dir, uri, referer, picture)
        @firefox = firefox
        @news_save = news_save
        @dest_dir = dest_dir
        @r18_dir = r18_dir

        @uri = uri
        @referer = referer
        @picture = picture

        @search_file = calc_search_image_pathname(uri)
        @regular_file = calc_regular_image_pathname(uri)
      end

      def download
        download_image(@uri, @referer, @picture)
      end

      def download_image(uri, referer, picture)
        if @search_file.exist?
          log "found search_file #{@search_file}. abort download."
          return
        end

        begin
          do_download_image(uri, referer, picture)
        rescue => e
          begin
            log "#{e.message} class=#{e.class} uri=#{uri}"
            pp e.backtrace
          end
        end
      end

      def do_download_image(uri, referer, picture)
        unless @regular_file.exist?
          fetch_image(uri, referer, @regular_file)
          if @news_save
            # newsフォルダにリンクを作成
            news_file = calc_news_image_pathname(uri)
            make_link_quietly(@regular_file, news_file)
          end
        end

        # キーワード毎のフォルダにリンクを作成
        make_link_quietly(@regular_file, @search_file)

        # r18のみのリンクを作成
        if @r18_dir && (picture.tags =~ /\bR-18\b/i)
          r18_file = @r18_dir.join(@regular_file.basename)
          make_link_quietly(@regular_file, r18_file)
        end
      end

      def fetch_image(uri, referer, file)
        log uri 
        binary = retry_fetch_with_timelag(message: uri) {
          @firefox.get_binary uri, 'Referer' => referer
        }
        write_binary_quietly(file, binary)
      end

      def calc_regular_image_pathname(uri)
        Pixiv::Config.regular_image_pathname_from_uri(uri)
      end

      def calc_search_image_pathname(uri)
        calc_pathname_in_dir(uri, @dest_dir)
      end

      def calc_news_image_pathname(uri)
        calc_pathname_in_dir(uri, NEWS_DIR)
      end

      def calc_pathname_in_dir(uri, dir)
        basename = fix_basename(uri.gsub(/\?.*/, '').split('/')[-1])
        file = dir.join('pixiv_' + basename)
        return file
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
        #FileUtils.ln_sf(old, new, verbose: VERBOSE)
        Crawlers::Util::Helpers::Etc.make_link_quietly(old, new, verbose: VERBOSE)
      end
    end
  end
end


