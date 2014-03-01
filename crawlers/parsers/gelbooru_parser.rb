# vim:set fileencoding=utf-8:

require 'mtk/import'
require_relative '../gelbooru/crawler'
require_relative '../util'
require_relative 'commons/dired_parser'

module Crawlers::Parsers
  class GelbooruParser
    def initialize(parent)
      @parent = parent
    end
    
    public
    def parse(lines)
      opt = parseOption(lines.shift.text)
      items = Commons::DiredParser.new.parse(lines)
      crawl(opt, items)
      @parent.parse(lines)
    end

    private
    def parseOption(command)
      opt = {}
      parser = OptionParser.new
      parser.on("--type=VAL"){|v|
        case v
        when "new"
          # 新規
          opt[:news_only] = false
          opt[:news_save] = false
        when "append"
          # 追加
          opt[:news_only] = true
          opt[:news_save] = true
        when "renew"
          # 取りこぼし取得
          opt[:news_only] = false
          opt[:news_save] = true
        end
      }
      parser.on("--image_count_per_page=VAL"){|v|
        var = case v
              when /^auto$/i
                :auto
              when /\d+/
                v.to_i
              else
                raise ArgumentError, "image_count_per_page is 'auto' or number"
              end
        opt[:image_count_per_page] =  var
      }
      parser.parse command.split(/\s+/)
      return opt
    end

    def crawl(opt, items)
      items.each do |item|
        do_crawl(item.keyword, item.dir, opt)
      end
    end

    def do_crawl(keyword, dest_dir, opt)
      @parent.add_invokers(Invoker.new(keyword, opt.merge({dest_dir: dest_dir})))
    end

    class Invoker
      include Crawlers::Util
      attr_reader :keyword

      def initialize  keyword, opt
        @keyword = keyword
        @opt = opt
      end
        
      def type
        return :gelbooru
      end

      def search_dir
        raise 'not implemented.'
        #dir_descend = @opt[:parent_dir].to_pathname.descend.map(&:basename) << @keyword
        #return dir_descend.map{|d| fix_basename(d.to_s)}.join('/').sub(%r{^/}, '')
      end

      def invoke
        #pp [@keyword, @opt]
        
        Gelbooru::Crawler.new(
          @keyword,
          @opt
        ).crawl
      end
    end
  end
end
