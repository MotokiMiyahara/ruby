# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'uri'
require 'cgi'
require 'pathname'

require_relative '../core'
require_relative 'models'

module Crawlers::DanbooruClones::Konachan
  class RemoteImage <  Crawlers::DanbooruClones::Core::AbstractRemoteImage

    def image_filename_prefix
      return 'konachan'
    end

    def model_class
      return KonachanImages
    end

    def calc_relative_save_dir(id, uri)
      reg = %r{/(image/[a-f0-9/]+/)Konachan\.com[-_%a-z0-9]+.[a-z]+}
      mdata = uri.path.match(reg)
      raise 'not match' unless mdata

      sub_dir = mdata.to_a[1]
      return Pathname(uri.host).join(sub_dir).cleanpath
    end
  end
end


