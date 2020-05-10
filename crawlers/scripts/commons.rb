# vim:set fileencoding=utf-8:

require 'forwardable'
require 'pathname'
require 'optparse'

require_relative 'require_lib'
require_lib 'util'

module Scripts
  extend self
  def self.included base
    base.__send__(:include, InstanceMethods)
  end
end

module Scripts::InstanceMethods
  extend Forwardable
  def_delegators(
    "Scripts::Helper",
    :script_header)

  def_delegators(
    "Scripts::Invoker",
    :invoke_browser)
end

class Scripts::Helper
  class << self
    public
    def script_header(*args)
      opt = parse_opt!
      change_stdio_to_file(opt)
      script_name = Pathname($0).basename
      if ARGV.size < args.size 
        args_info = args.map{|arg| "{#{arg}}"}.join(' ')
        raise "usage: ruby #{script_name} #{args_info}"
      end

      # コマンドライン引数のエンコードを強制的にUTF-8にする
      ARGV.map!{|s| s.encode('UTF-8', Crawlers::Util.platform_lang)}
    end

    private 
    def parse_opt!
      opt = {}
      parser = OptionParser.new
      parser.on('--with_log_file', 'redirect stdout and stderr to "out.log"'){opt[:do_redirect] = true}
      parser.order!(ARGV)
      return opt
    end
    def change_stdio_to_file(opt)
      return unless opt[:do_redirect]
      #fp = File.open(Pathname($0).dirname.join("out.log"), "w:UTF-8")
      fp = File.open(Pathname($0).dirname.join("out.log"), "w")
      $stdout = fp
      $stderr = fp
    end
  end
end

class Scripts::Invoker
  #APP_BROWSER = "C:/Program Files/Mozilla Firefox/firefox.exe"
  APP_BROWSER = 'C:/Program Files/Mozilla Firefox/firefox.exe'

  class << self
    include Crawlers::Util
    def invoke_browser(uri)
      dos(APP_BROWSER, uri)
    end
  end
end
