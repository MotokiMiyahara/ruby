#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'fileutils'
require 'uri'
require 'clipboard'
require 'csv'
require 'mtk/import'
require 'mtk/net/firefox'
require_relative 'commons'
require_relative '../config'
require_relative '../util'
#require_relative '../pixiv/user_crawler'
#
require 'httpclient'
require 'nokogiri'


module Scripts; end
class Scripts::SearchImageDetail

  USER_AGENT = 'Mozilla/5.0 (Windows NT 5.1; rv:25.0) Gecko/20100101 Firefox/25.0'
  SEARCH_URI = 'http://www.ascii2d.net/imagesearch/search'

  class << self
    def execute(image_filename)
      doc = get_document(image_filename)
      link = doc.at_css('a')[:href]
      invoke_browser(link)
    end

    def get_document(image_filename)
      html = get_html(image_filename)
      return Nokogiri::HTML(html)
    end

    def get_html(image_filename)
      open(image_filename, 'rb') do |image| 
        client = HTTPClient.new(agent_name: USER_AGENT)
        res = client.post(SEARCH_URI, {'upload[file]' => image})
        return res.body
      end
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header
  image_filename = ARGV[0]
  Scripts::SearchImageDetail::execute(image_filename)
end



