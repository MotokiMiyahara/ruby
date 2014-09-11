# vim:set fileencoding=utf-8:

require_relative 'modules'
require_relative '../../danbooru_clones/konachan/crawler'
require_relative 'core'

module Crawlers::Parsers::DanbooruClones

  class KonachanParser < Core::AbstractParser

    private
    def create_invoker(keyword, opt)
      return Invoker.new(keyword, opt)
    end

    class Invoker < Core::AbstractInvoker
      def type
        return :konachan
      end

      def invoke
        Konachan::Crawler.new(
          keyword,
          opt
        ).crawl
      end
    end
  end
end
