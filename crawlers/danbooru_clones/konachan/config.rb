# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'my/config'
require_relative '../../errors'
require_relative '../../config'
require 'uri'
require 'pp'


module Konachan
  #SITE_DIR      = My::CONFIG.dest_dir + 'crawler/gelbooru'
  SITE_DIR      = Crawlers::Config::app_dir + 'konachan'
  NEWS_DIR      = SITE_DIR + "news"
  SEARCH_DIR    = SITE_DIR + "search"
  ALL_IMAGE_DIR = SITE_DIR + ".all_images"
end


if $0 == __FILE__

end

