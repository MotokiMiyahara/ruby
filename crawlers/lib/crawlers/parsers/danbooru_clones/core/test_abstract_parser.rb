# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'modules'
require_relative 'abstract_parser'
require_relative '../../commons/line'

module Crawlers::Parsers::DanbooruClones::Core

  class TestAbstractParser < AbstractParser

    class << self
      def parse(file)
        lines = Crawlers::Parsers::Commons::Line.parse_file(file)
        parser = new
        parser.parse(lines)

        result = ParseResult.new
        result.items = parser.items
        result.opts = parser.opts
        return result
      end
    end

    public
    def items
      return @test_items
    end

    def opts
      return @test_opt
    end

    private
    def initialize
      env = FakeEnv.new
      noop = true
      super(env, noop)
    end

    def crawl(items, opt)
      @test_items = items
      @test_opt = opt
    end

    class Invoker < AbstractInvoker
      def type
        return :test
      end

      def invoke
        raise 'Should not reach here.'
      end
    end

    class ParseResult < Struct.new(:items, :opts); end
    class FakeEnv
      def parse(*args)
        # nop
      end
    end
  
  end
end

if $0 == __FILE__

end

