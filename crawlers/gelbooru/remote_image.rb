# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'uri'
require 'cgi'
require 'pathname'

module Gelbooru
  class Crawler
    class RemoteImage
      include Crawlers::Util

      PREFIX = 'gelbooru'

      attr_reader :search_file
      def initialize(thumbnail_uri, display_uri, dest_dir, news_save, fire_fox)
        @uri = thumbnail_uri.sub(%r{thumbnails}, 'images').sub(%r{thumbnail_}, '')
        @id  = CGI.parse(URI(display_uri).query)['id'][0]

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
        file = dir.join("#{PREFIX}_#{@id}_#{basename}")
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


