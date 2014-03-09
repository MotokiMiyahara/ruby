# vim:set fileencoding=utf-8:

require 'optparse'
require 'pp'

require 'mtk/concurrent/thread_pool'
require 'mtk/import'
require_relative '../pixiv/picture'
require_relative 'modules'

module Crawlers::Parsers
  class Crawlers::Parsers::DslParser

    attr_reader :invokers
    def initialize(parent, **opts)
      @opts = opts
      @parent = parent
      @file   = opts[:file]
      @noop   = opts[:noop]
    end

    public
    def parse_file
      puts "parsing: #{@file}"
      lines = Crawlers::Parsers::Commons::Line::parse_file(@file)
      parse(lines)
    end

    #---------------------------
    # :section: toplevel
    #---------------------------

    def parse(lines)
      return unless lines.first
      case lines.first.text
      when /^:pixiv/
        PixivParser.new(self, @pixiv_db).parse(lines)
      when /^:yandere/
        #YandereParser.new(self, @yandere_pool).parse(lines)
        YandereParser.new(self).parse(lines)
      when /^:gelbooru/
        GelbooruParser.new(self, @noop).parse(lines)
      when /^:include/
        IncludeParser.new(self, @file, **@opts).parse(lines)
      else
        raise "undefined command: #{lines.first}"
      end
    end


    #---------------------------
    # :section: invokers
    #---------------------------
    def add_invoker(invoker)
      @parent.add_invoker(invoker)
    end
  end
end

