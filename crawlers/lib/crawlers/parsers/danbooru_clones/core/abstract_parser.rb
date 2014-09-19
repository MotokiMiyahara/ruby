# vim:set fileencoding=utf-8:

require'tapp'
require 'shellwords'
require 'mtk/import'

require_relative 'modules'
require_relative '../../commons/dired_parser'

module Crawlers::Parsers::DanbooruClones::Core

  module Helper
    module_function

    # 排他的なキーワードリストを生成する
    # @example
    #  expand_exclusive_keywords(%w{a, b, c}) => ["a", "b -a", "c -b -a"]
    def expand_exclusive_keywords(keyword_list)
      return ([''] + keyword_list).each_index.map { |index|
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

  class AbstractParser
    COMMON_KEYWORD = '-photo -animated '

    SHIFT_KEYWORDS = [
      'pussy',
      'nipples',
      'rating:explicit',
      '-rating:safe',
    ]

    def initialize(parent, noop)
      @parent = parent
      @noop = noop
    end
    
    public
    def parse(lines)
      opt, p_opt = parse_option(lines.shift.text)

      items = Crawlers::Parsers::Commons::DiredParser.new.parse(lines)
      items = expand_items(items, p_opt)

       crawl(items, opt)
      @parent.parse(lines)
    end

    private
    def parse_option(command)
      opt = {noop: @noop}
      p_opt = {
        all: COMMON_KEYWORD,
        shift: SHIFT_KEYWORDS
      }
      parser = OptionParser.new
      parser.on("--type=VAL"){|v|
        case v
        when "new"
          # 新規
          opt[:news_only] = false
          opt[:news_save] = false
          opt[:image_count_per_page] = :max

        when "append"
          # 追加
          opt[:news_only] = true
          opt[:news_save] = true
          opt[:image_count_per_page] = :auto
        when "renew"
          # 取りこぼし取得
          opt[:news_only] = false
          opt[:news_save] = true
          opt[:image_count_per_page] = :max
        else
          raise "wrong type: #{v}"
        end
      }

      # 一ページあたりの画像数
      parser.on("--image_count_per_page=VAL"){|v|
        var = case v
              when /^auto$/i
                :auto
              when /^max$/i
                :max
              when /\d+/
                v.to_i
              else
                raise ArgumentError, "image_count_per_page is 'auto' or number"
              end
        opt[:image_count_per_page] = var
      }

      parser.on("--min_page=VAL"){|v| opt[:min_page] = v.to_i}
      parser.on("--max_page=VAL"){|v| opt[:max_page] = v.to_i}

      parser.on("--shift=VAL"){|v| p_opt[:shift] = v.split(/\s+/)}
      parser.on("--all=VAL"){|v| p_opt[:all] = v}

      parser.parse(Shellwords.split(command))
      return opt, p_opt
    end

    # $で始まるキーワードを展開する
    def expand_items(items, p_opt)
      parsed_items = items.flat_map{|item|
        unless item.keyword =~ /^\$/
          next create_item(item.categories, join_keywords(item.keyword, p_opt[:all]))
        end

        base_keyword = item.keyword.sub(/^\$/, '')
        new_categories = item.categories + [base_keyword]
        
        extra_keywords = Helper::expand_exclusive_keywords(p_opt[:shift])
        expanded_items = extra_keywords.map{|extra_keyword|
          new_keyword = join_keywords(base_keyword, extra_keyword, p_opt[:all])
          create_item(new_categories, new_keyword)
        }

        next expanded_items
      }
      return parsed_items
    end

    def join_keywords(*keywords)
      return keywords.flat_map{|k| k.split(/\s+/)}.reject(&:empty?).join(' ')
    end

    def create_item(categories, keyword)
      return Crawlers::Parsers::Commons::DiredParser::Item.new(categories, keyword)
    end

    def crawl(items, opt)
      items.each do |item|
        do_crawl(item.keyword, opt.merge({parent_dir: item.dir.parent}))
      end
    end

    def do_crawl(keyword, opt)
      invoker = create_invoker(keyword, opt)
      @parent.add_invoker(invoker)
    end

    def create_invoker(keyword, opt)
      raise 'abstract method'
      # exsample
      #   return XxxxInvoker.new(keyword, opt)
    end


  end

  class AbstractInvoker
    #include Crawlers::Util
    attr_reader :keyword

    def initialize(keyword, opt)
      @keyword = keyword
      @opt = opt
    end

    def search_dir
      raise 'not implemented.'
    end

    def type
      raise 'abstract method'
    end

    def invoke
      raise 'abstract method'
    end

    private
    def opt
      return @opt
    end
  end
end
