# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'my/config'
require 'pp'

require_relative 'modules'
require_relative '../config'


module Hentai
  class Config
    class << self

      def site_dir
        return Crawlers::Config::app_dir + site_name
      end
      private
      def site_name
        return 'hentai'
      end
    end
  end
end

