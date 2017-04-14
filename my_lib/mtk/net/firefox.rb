# vim:set fileencoding=utf-8:

require 'rubygems'
require 'sqlite3'
require 'uri'
require 'pp'
require 'nokogiri'
require "rbconfig"

require 'open_uri_redirections'

require 'mtk/net/uri_getter'

module Mtk
  module Net
    class Firefox

      attr_reader :cookie
      def initialize
        @cookie = Cookie.new
          #@user_agent = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"
          #@user_agent = 'Mozilla/5.0 (Windows NT 5.1; rv:25.0) Gecko/20100101 Firefox/25.0'
          @user_agent = 'Mozilla/5.0 (Windows NT 5.1; rv:30.0) Gecko/20100101 Firefox/30.0'

      end


      def get_document(*args)
        html = get_html_as_utf8(*args)
        doc = Nokogiri::HTML(html, nil, 'UTF-8')
        return doc
      end

      def get_html_as_utf8(uri, *args)
        options = default_options(uri)
        opts = args[-1].is_a?(Hash) ? args.pop : {}
        options.merge! opts
        return UriGetter.get_html_as_utf8(uri, *args, options)
      end

      def get_binary(uri, *args)
        options = default_options(uri)
        opts = args[-1].is_a?(Hash) ? args.pop : {}
        options.merge! opts
        return UriGetter.get_binary(uri, *args, options)
      end


      private
      def default_options(uri)
        uri = URI(uri)
        options = {
          'User-Agent' => @user_agent, 
          :allow_redirections => :safe,
          #'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          #'Accept-Language'   => 'ja,en-us;q=0.7,en;q=0.3',
          #'Accept-Encoding'   => 'gzip, deflate',
          #'Connection'        => 'keep-alive',
          #'Cache-Control'     => 'max-age=0',
          "Cookie" => @cookie[uri.host]
        }
        return options
      end

      class Cookie
        include SQLite3
        def initialize
          @data_file = find_cookie_file
          @cache = {}
        end

        public 
        def [](a_base_domain)
          base_domain = a_base_domain.sub(/^www\./, '')
          cache = @cache[base_domain]
          return cache if cache

          with_database do |db|
            data = []
            binds = {'base_domain' => base_domain}
            db.execute(%q{select * from moz_cookies where baseDomain=:base_domain;}, binds) do |row|
              pair = row['name'] << '=' << row['value'] 
              data << pair
            end
            cookies = data.join("; ")

            @cache[base_domain] = cookies
            return cookies
          end
        end

        private
        def find_cookie_file
          pattern = case os
                    when :win
                      "#{ENV['APPDATA']}/Mozilla/Firefox/Profiles/**/cookies.sqlite".gsub('\\', '/')
                    when :linux
                      "#{ENV['HOME']}/.mozilla/firefox/**/cookies.sqlite"
                      #"/home/mtk/samba/**/cookies.sqlite"
                    else
                      raise "not supported os."
                    end

          data_files = Dir.glob(pattern)
          raise "Perhaps Firefox is not installed." if data_files.size == 0
          return data_files[0]
        end

        def with_database
          raise ArgumentError unless block_given?
          db = Database.new(@data_file)
          db.results_as_hash = true
          db.transaction do
            yield db
          end
        ensure
          db.close
        end

        def os
          osn = RbConfig::CONFIG["target_os"].downcase
          return osn =~ /mswin(?!ce)|mingw|cygwin|bccwin/ ? :win : (osn =~ /linux/ ? :linux : :other)
        end
      end
    end
  end
end


