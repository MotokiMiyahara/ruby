# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pathname'

module Scripts
  module LibLoader

    LIB_PATH = File.expand_path('../lib', __dir__)
    module_function
    def require_lib(path)
      require File.expand_path(path, LIB_PATH)
    end
  end
end

include Scripts::LibLoader

if $0 == __FILE__
  puts Scripts::LibLoader::LIB_PATH
end

