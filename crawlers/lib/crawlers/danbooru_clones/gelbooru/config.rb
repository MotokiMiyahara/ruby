# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative '../../errors'
require_relative '../../config'
require 'uri'
require 'pp'

require_relative '../core'

module Crawlers::DanbooruClones::Gelbooru
  class Config < Crawlers::DanbooruClones::Core::AbstractConfig
    class << self
      def site_name
        return 'gelbooru'
      end
    end
  end
end


if $0 == __FILE__
  pp Crawlers::DanbooruClones::Gelbooru::Config.all_image_dir
end

