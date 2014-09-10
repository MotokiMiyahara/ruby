# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'my/config'
require_relative '../errors'
require_relative '../config'
require 'uri'
require 'pp'


module Gelbooru
  #SITE_DIR      = My::CONFIG.dest_dir + 'crawler/gelbooru'
  SITE_DIR      = Crawlers::Config::app_dir + 'gelbooru'
  NEWS_DIR      = SITE_DIR + "news"
  SEARCH_DIR    = SITE_DIR + "search"
  ALL_IMAGE_DIR = SITE_DIR + ".all_images"
  #
  #USER_DIR      = PIXIV_DIR + "user"
end


if $0 == __FILE__

end

