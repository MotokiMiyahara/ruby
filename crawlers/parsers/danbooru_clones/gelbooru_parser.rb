# vim:set fileencoding=utf-8:

require_relative 'modules'
require_relative '../../gelbooru/crawler'
require_relative 'core'

module Crawlers::Parsers::DanbooruClones

  class GelbooruParser < Core::AbstractParser

    private
    def create_invoker(keyword, opt)
      return Invoker.new(keyword, opt)
    end

    class Invoker < Core::AbstractInvoker
      def type
        return :gelbooru
      end

      def invoke
        Gelbooru::Crawler.new(
          keyword,
          opt
        ).crawl
      end
    end

  end
end
