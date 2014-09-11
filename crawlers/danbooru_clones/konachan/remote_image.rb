# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'uri'
require 'cgi'
require 'pathname'

require_relative '../core'
require_relative 'db'

module Konachan
  class RemoteImage <  Crawlers::DanbooruClones::Core::AbstractRemoteImage
    def model_class
      return KonachanImages
    end
  end
end


