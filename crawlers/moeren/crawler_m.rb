# vim:set fileencoding=utf-8:

require 'fileutils'
require 'pp'

require'my/my'
require 'mtk/concurrent/thread_pool'
require 'mtk/net/uri_getter'

require_relative 'config'

module Moeren
  module Crawler_m
    include Mtk::Net

    def self.abstract(*args)
      name = self.name
      args.each do |sym|
        define_method sym do
          raise "not implementd #{sym}. required by #{name}"
        end
      end
    end

    def initialize opts
      @log_proc = opts[:log_proc] || proc{|*args| puts(*args)}
      Dir.mkdir dest_dir unless Dir.exists? dest_dir
    end

    public
    def crawl
      do_crawl root_uri
    end

    private
    def do_crawl(base_uri)
      begin
        html = UriGetter.get_html_as_utf8(base_uri)
      rescue SocketError => e
        puts "Not found: " + base_uri + " (#{e})"
        return
      end

      # 画像のダウンロード
      image_uris(base_uri, html).each do |image_uri|
        push_task do
          begin
            image_file = calc_image_path image_uri
            next if File.exists? image_file

  log image_uri

            image_binary = UriGetter.get_binary image_uri
            open(image_file, "wb") do |f|
              f.write image_binary
            end

            # newsフォルダへコピー
            FileUtils.link(image_file, Moeren::Config::NEWS_DIR) unless Moeren::Config::NEWS_DIR.join(image_file.basename).exist?

          rescue => e
            puts e
            puts e.backtrace
          end
        end
      end

      # 次ページがあればそれも解析
      next_uri = next_uri(base_uri, html)
      do_crawl next_uri if next_uri
    end

    def dest_dir
      return Moeren::Config::DEST_DIR.join(dest_sub_dir_name)
    end

    def calc_image_path url
      image = url.split('/')[-1]
      return dest_dir.join(image)
    end

    def log *args
      @log_proc.call(*args) if @log_proc
    end


    abstract :root_uri,
             :dest_sub_dir_name,
             :image_uris,
             :next_uri,           # 次ページが無い時はnilを返す
             :push_task
  end
end
