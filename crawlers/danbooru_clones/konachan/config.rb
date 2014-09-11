# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative '../../errors'
require_relative '../../config'
require 'uri'
require 'pp'

require_relative '../core'

module Konachan
  class Config < Crawlers::DanbooruClones::Core::AbstractConfig
    class << self
      def site_name
        return 'konachan'
      end
    end
  end
end


if $0 == __FILE__
  pp Konachan::Config.all_image_dir
end

