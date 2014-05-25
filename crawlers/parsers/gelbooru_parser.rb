# vim:set fileencoding=utf-8:

#require'tapp'
require 'mtk/import'
require_relative '../gelbooru/crawler'
require_relative '../util'
require_relative 'commons/dired_parser'

module Crawlers::Parsers

  module Helper
    module_function

    # 排他的なキーワードリストを生成する
    # @example
    #  expand_exclusive_keywords(%w{a, b, c}) => ["a", "b -a", "c -b -a"]
    def expand_exclusive_keywords(keyword_list)
      return keyword_list.each_with_index.map { |_, index|
        first = keyword_list[index]
        rest = keyword_list[0...index].reverse.map{|keyword|
          case keyword
          when /^-/
            keyword.sub(/^-/, '')
          else
            '-' + keyword
          end
        }
        next ([first] + rest).join(' ')
      }
    end
  end

  class GelbooruParser
    COMMON_KEYWORD = '-photo'
    EXTRA_KEYWORDS = Helper::expand_exclusive_keywords([
      'pussy',
      'nipples',
      'rating:explicit',
      '-rating:safe',
    ])

    def initialize(parent, noop)
      @parent = parent
      @noop = noop
    end
    
    public
    def parse(lines)

      opt = parseOption(lines.shift.text)
      items = Commons::DiredParser.new.parse(lines)
      items = expand_items(items)

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
      opt[:noop] = @noop
      return opt
    end

    # $で始まるキーワードを展開する
    def expand_items(items)
      parsed_items = items.flat_map{|item|
        next [item] unless item.keyword =~ /^\$/

        base_keyword = item.keyword.sub(/^\$/, '')
        new_categores = item.categories + [base_keyword]
        
        expanded_items = EXTRA_KEYWORDS.map{|extra_keyword|
          new_keyword = [base_keyword, extra_keyword, COMMON_KEYWORD].join(' ')
          Commons::DiredParser::Item.new(new_categores, new_keyword)
        }

        next expanded_items
      }
      return parsed_items
    end

    def crawl(opt, items)
      items.each do |item|
        do_crawl(item.keyword, item.dir.parent, opt)
      end
    end

    def do_crawl(keyword, parent_dir, opt)
      @parent.add_invoker(Invoker.new(keyword, opt.merge({parent_dir: parent_dir})))
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
