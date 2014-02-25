# vim:set fileencoding=utf-8:

require 'mtk/import'
#require_relative '../pixiv/crawler'
require_relative '../pixiv/parallel_cralwler'
require_relative '../util'
require_relative 'commons/dired_parser'

module Crawlers::Parsers
  class PixivParser
    #include Crawlers::Util

    def initialize parent, db
      @parent = parent
      @db = db
    end
    
    public
    def parse lines
      opt = parseOption lines.shift.text
      dirs_and_keywords = shift_keywords lines
      crawl opt, dirs_and_keywords
      @parent.parse lines
    end

    private
    def parseOption command
      opt = {
        db: @db
      }
      parser = OptionParser.new
      parser.on("--type=VAL"){|v|
        case v
        when "new"
          # 新規
          opt[:min_page] = 1
          opt[:max_page] = 5001
          opt[:news_only] = false
          opt[:news_save] = false
        when "append"
          # 追加
          opt[:min_page] = 1
          #opt[:max_page] = 100
          opt[:max_page] = 200
          opt[:news_only] = true
          opt[:news_save] = true
        when "renew"
          # 取りこぼし取得
          opt[:min_page] = 1
          opt[:max_page] = 50
          opt[:news_only] = false
          opt[:news_save] = true
        when "norm_to_premium"
          # 通常アカウントからpixiv premiumへ移行したときに追加分を取得
          opt[:min_page] = 1000
          opt[:max_page] = 5001
          opt[:news_only] = false
          opt[:news_save] = false
        end
        opt[:r18] = (v == "true")
      }
      #parser.on("--dir=VAL"){|v| opt[:parent_dir] = v}
      parser.on("--r18=VAL"){|v| opt[:r18] = (v == "true")}
      parser.on("--min_page=VAL"){|v| opt[:min_page] = v.to_i}
      parser.on("--max_page=VAL"){|v| opt[:max_page] = v.to_i}
      parser.parse command.split(/\s+/)
      return opt
    end

    def crawl(opt, dirs_and_keywords)
      dirs_and_keywords.each do |item|
        do_crawl(item.keyword, item.dir.parent.to_s, opt)
      end
    end

    def do_crawl(keyword, dir, opt)
      @parent.add_invokers(PixivInvoker.new(keyword, opt.merge({parent_dir: dir})))
    end

    def shift_keywords lines
      Commons::DiredParser.new.parse(lines)
    end

    class PixivInvoker
      include Crawlers::Util
      attr_reader :keyword

      def initialize  keyword, opt
        @keyword = keyword
        @opt = opt
      end
        
      def type
        return :pixiv
      end

      def search_dir
        dir_descend = @opt[:parent_dir].to_pathname.descend.map(&:basename) << @keyword
        return dir_descend.map{|d| fix_basename(d.to_s)}.join('/').sub(%r{^/}, '')
      end

      def invoke
        #pp [@keyword, @opt]
        
        Pixiv::ParallelCrawler.new(
          @keyword,
          @opt
        ).crawl
      end
    end
  end
end
