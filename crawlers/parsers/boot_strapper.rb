# vim:set fileencoding=utf-8:

require 'optparse'
require 'pp'

require_relative '../pixiv/picture'
require_relative 'modules'

module Crawlers::Parsers
  class Crawlers::Parsers::BootStrapper

    attr_reader :invokers
    def initialize(**opts)
      @opts = opts
      @opts[:file] ||= Pathname(__FILE__).dirname.join("../dsl/dsl.txt")
    end

    public
    def start
      tlog('start')
      invokers = parse_invokers
      invokers.each(&:invoke)
      tlog('end' + @file.to_s)
    end

    def parse_invokers
      env = Env.new
      parser = DslParser.new(env, @opts)
      parser.parse_file # parse_fileすることでenv#invokersにコマンドが蓄積される
      return env.invokers
    end

    class Env
      def initialize
        @invokers = []
      end

      def invokers
        return @invokers.dup
      end

      def add_invoker(invoker)
        @invokers << invoker
      end
    end
  end
end

