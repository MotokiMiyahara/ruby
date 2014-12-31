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
    #THREAD_COUNT_GET_IMAGE_URLS = 3

    def crawl(uri)
      index_uri = replace_query(URI(uri), 'p' => '0')
      begin
        crawl_index(index_uri)
      rescue Mechanize::ResponseCodeError, Mechanize::ResponseReadError => e
        log("#{e} #{e.class.name}")
        sleep(rand(3 .. 5))
        retry
      end
    end

    def create_agent
      agent = Mechanize.new
      agent.user_agent_alias = 'Windows Mozilla'
      agent.keep_alive = false
      return agent
    end

    def crawl_index(uri)
      @agent = create_agent

      page = @agent.get(uri)
      h1 = page.at('h1')
      if h1 && h1.text =~ /Content\s+Warning/i
        # 警告ページに飛ばされた
        index_page = page.link_with(text: /View\s+Gallery/i).click()
      else
        # indexページにいる
        index_page = page
      end
      
      #pp index_page
      title = index_page.at('#gj').text.strip
      title = title.empty? ? index_page.at('#gn').text.strip : title
      title.gsub!(/^\.\./, '')
      title.gsub!('/', '_')

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

        figs = current_page.at('.ip').text.match(/[0-9,]+\s*-\s*([0-9,]+)\s*of\s*([0-9,]+)/).to_a.values_at(1, 2)
        figs.map!{|fig| fig.gsub(',', '')}.map!(&:to_i)
        larger_image_number, max_image_number = *figs

        #pp [max_image_number ,larger_image_number]
        break if max_image_number <= larger_image_number 

        current_page_number = extract_query_value(current_page.uri, 'p', default: 0).to_i
        next_page_number = current_page_number + 1
        next_uri = replace_query(current_page.uri, 'p' => next_page_number)
        current_page = @agent.get(next_uri.to_s)
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

      #Parallel.map(view_links, in_threads: THREAD_COUNT_GET_IMAGE_URLS) {|link|
      #
      
      agent = create_agent
      view_links.each {|link|
        guess_filename = link.node.at('img')[:title]
        guess_dest = @dest_dir + guess_filename
        next if guess_dest.exist?

        view_page = agent.get(link.uri)
        src_uri = view_page.at('#img')['src']


        guess2_filename = src_uri.split('/')[-1]
        guess2_dest = @dest_dir + guess2_filename

        next if guess2_dest.exist?

        log(src_uri)
        begin 
          src = agent.get(src_uri)
        rescue Net::HTTP::Persistent::Error, Errno::EHOSTUNREACH => e
          log("skip: #{src_uri} Because of #{e}(#{e.class.name})")
          next
        end 

        dest = @dest_dir + src.filename
        next if dest.exist?
        log("-save: #{src.filename}")
        src.save_as(dest) 
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

