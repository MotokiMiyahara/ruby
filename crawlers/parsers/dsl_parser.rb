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
    def initialize(
        file: Pathname(__FILE__).dirname.join("../dsl.txt"),
        noop: false)
      #@file = file || __FILE__.to_pathname.dirname.join("../dsl.txt")
      
      @file = file 
      @noop = noop

      @yandere_pool = 
        Mtk::Concurrent::ThreadPool.new(
          max_producer_count: 3,
          max_consumer_count: 5)
      @pixiv_db = nil

      @invokers = []
    end

    public
    def start
      tlog('start')
      Pixiv::PictureDb.open do |db|
        #@pixiv_db = db
        @pixiv_db = nil

        parse_file # parse_fileすることで@invokersにコマンドが蓄積される
        @invokers.each(&:invoke)

        #Pixiv::Crawler.join
        @yandere_pool.join
      end
      tlog('end')
    end

    def parse_file
      #open(@file, "r:UTF-8")do |f|
      #  lines = f.each_line.map{|line| Line.new(line)}.reject{|line| line.blank?}
      #  parse lines
      #end

      lines = Crawlers::Parsers::Commons::Line::parse_file(@file)
      parse(lines)
    end

    #---------------------------
    # :section: toplevel
    #---------------------------

    def parse lines
      return unless lines.first
      case lines.first.text
      when /^:pixiv/
        PixivParser.new(self, @pixiv_db).parse(lines)
      when /^:yandere/
        YandereParser.new(self, @yandere_pool).parse(lines)
      when /^:gelbooru/
        GelbooruParser.new(self, @noop).parse(lines)
      else
        raise "undefined command: #{lines.first}"
      end
    end


    #---------------------------
    # :section: invokers
    #---------------------------
    def add_invokers invoker
      @invokers << invoker
    end

    private

  end


end

