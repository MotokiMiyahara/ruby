# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'my/config'
require 'pp'

require_relative 'modules'


module Crawlers::DanbooruClones::Core
  class AbstractConfig
    class << self

      def site_dir
        return Crawlers::Config::app_dir + site_name
      end

      def news_dir
        return site_dir + "news"
      end

      def search_dir
        return site_dir + "search"
      end

      def all_image_dir
        return site_dir +  ".all_images"
      end

      def verbose
        return false
      end

      private
      def site_name
        raise 'abstract method'
      end
    end
  end
end

