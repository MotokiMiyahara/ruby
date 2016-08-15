# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'uri'
require 'cgi'
require 'pathname'

require_relative '../core'
require_relative 'models'

module Crawlers::DanbooruClones::Gelbooru
  class RemoteImage <  Crawlers::DanbooruClones::Core::AbstractRemoteImage

    def image_filename_prefix
      return 'gelbooru'
    end

    def model_class
      return GelbooruImages
    end

    def calc_relative_save_dir(id, uri)
      reg = %r{^/(images/[a-f0-9/]+)/[a-f0-9]+\.[a-z]+}
      mdata = uri.path.match(reg)
      raise 'not match' unless mdata

      sub_dir = mdata.to_a[1]
      #puts '-----------------------------------------'
      #pp sub_dir
      result = Pathname(sub_dir).cleanpath
      return result
    end
  end
end


