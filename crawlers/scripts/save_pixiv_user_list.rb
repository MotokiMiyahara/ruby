#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'fileutils'
require 'uri'
require 'clipboard'
require 'csv'
require 'mtk/import'
require 'mtk/net/firefox'

require_relative 'commons'
require_lib 'config'
require_lib 'util'
require_lib 'pixiv/user_crawler'


module Scripts; end
class Scripts::SavePixivUserList
  class << self
    def execute
      #puts 'Please input (url \n)+ And ^D'

      lines = readlines
      ids = lines.map{|line| line.match(%r{http://www\.pixiv\.net/member(?:_illust)?\.php\?.*\bid=(\d+)}).to_a[1]}.compact
      pp ids

      Pixiv::UserCrawler::UserData.add_user_list(ids)
    end
  end
end

if $0 == __FILE__
  include Scripts
  #script_header(:user_url_file)
  script_header
  Scripts::SavePixivUserList::execute
end



