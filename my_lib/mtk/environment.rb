# vim:set fileencoding=utf-8:

require "rbconfig"

module Mtk
  class Environment
    class << self
      def os
        osn = RbConfig::CONFIG["target_os"].downcase
        return osn =~ /mswin(?!ce)|mingw|cygwin|bccwin/ ? :win : (osn =~ /linux/ ? :linux : :other)
      end
    end
  end
end
