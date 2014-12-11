# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'modules'
require_relative 'config'

require 'mechanize'
require 'uri'
require 'parallel'
require 'tapp'
require_relative '../util'

#require 'pry'

module Hentai
  class Crawler 
    include Crawlers::Util
    THREAD_COUNT_GET_IMAGE_URLS = 10

    def crawl(uri)
      index_uri = replace_query(URI(uri), 'p' => '0')
      crawl_index(index_uri)
    end

    def create_agent
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Mozilla'
      return agent
    end

    def crawl_index(uri)
      @agent = create_agent

      index_page = @agent.get(uri)
      title = index_page.at('#gj').text.strip
      log("title: #{title}")

      @dest_dir = Config.site_dir + title
      @dest_dir.mkdir unless @dest_dir.exist?

      list_pages = fetch_list_pages(uri)

      #pp list_pages.map(&:uri)

      list_pages.each do |page|
        crawl_list_page(page)
      end

    end

    def fetch_list_pages(uri)
      index_page = @agent.get(uri)

      current_page = index_page
      list_pages = []

      loop do
        list_pages << current_page
        larger_image_number, max_image_number = current_page.at('.ip').text.match(/\d+\s*-\s*(\d+)\s*of\s*(\d+)/).to_a.values_at(1, 2).map(&:to_i)

        #pp [max_image_number ,larger_image_number ]
        break if max_image_number <= larger_image_number 

        current_page_number = extract_query_value(current_page.uri, 'p', default: 0).to_i
        next_page_number = current_page_number + 1
        next_uri = replace_query(current_page.uri, 'p' => next_page_number)

        current_page = @agent.get(next_uri.to_s)
        #pp current_page.uri
      end

      return list_pages
    end

    def extract_query_value(uri, name, default: nil)
      uri = URI(uri)
      return default unless uri.query

      q = Hash[*URI::decode_www_form(uri.query).flatten]
      value = q[name]

      return default unless value
      return value
    end

    # @param [String | URI]
    # @return [String]
    def replace_query(uri, hash)
      uri = URI(uri)

      query = uri.query ? uri.query : ""
      q = Hash[*URI::decode_www_form(query).flatten]
      next_q = q.merge(hash)
      next_query = URI::encode_www_form(next_q)

      next_uri = URI::Generic.build({
          scheme:   uri.scheme,
          userinfo: uri.userinfo,
          host:     uri.host,
          port:     uri.port,
          registry: uri.registry,
          path:     uri.path,
          opaque:   uri.opaque,
          query:    next_query,
          fragment: uri.fragment
        })

      return next_uri.to_s
    end

    def crawl_list_page(page)
      view_links = page.links_with(search: '#gdt .gdtm a')

      Parallel.map(view_links, in_threads: THREAD_COUNT_GET_IMAGE_URLS) {|link|
        agent = create_agent
        view_page = agent.get(link.uri)

        src_uri = view_page.at('#img')['src']
        log(src_uri)

        src = agent.get(src_uri)
        dest = @dest_dir + src.filename
        src.save_as(dest) unless dest.exist?
      }
    end
  end
end




if $0 == __FILE__
  url = ARGV[0]
  raise 'usage: ./hentai {url}' unless url
  Hentai::Crawler.new.crawl(url)
  
  #Hentai::Crawler.new.crawl("http://g.e-hentai.org/g/761805/2b569fab0d/")
end

