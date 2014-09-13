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
class Scripts::SavePixivUser
  class << self
    def execute
      uri = Clipboard.paste
      raise "uri not match uri=#{uri}" unless uri =~ %r{http://www\.pixiv\.net/member(?:_illust)?\.php\?.*\bid=(\d+)}

      id = $1
      Pixiv::UserCrawler::UserData.add_user(id)
    end
  end
end

if $0 == __FILE__
  include Scripts
  script_header()
  Scripts::SavePixivUser::execute
end



