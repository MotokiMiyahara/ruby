# vim:set fileencoding=utf-8:

require 'mtk/import'
#require_relative '../pixiv/crawler'
require_relative '../pixiv/parallel_cralwler'
require_relative '../util'

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
    dirs_and_keywords.each do |elm|
      dir = elm[0]
      keywords = elm[1]
      keywords.each do |keyword|
        do_crawl(keyword, dir, opt)
      end
    end
  end

  def do_crawl(keyword, dir, opt)
    #Pixiv::Crawler.new(
    #  keyword,
    #  opt.merge({dir: dir})
    #)#.crawl
    #@parent.add_invokers({keyword: keyword, opt: opt.merge({dir: dir})})
    
    @parent.add_invokers(PixivInvoker.new(keyword, opt.merge({dir: dir})))
  end

  def shift_keywords lines
    return ShiftKeywords.new.execute lines
  end

  # method object
  class ShiftKeywords
    def initialize
      @keywords_list = []
      @dirs = []

      @keywords = []
      @dir_list = [""]
      @dir_indents = [-1]
    end

    def save_category
        @dirs << @dir_list.last
        @keywords_list << @keywords
        @keywords = []
    end

    def pop_category line
        z = @dir_indents.zip(@dir_list).reject{|e| indent = e[0]; line.indent <= indent}
        @dir_indents, @dir_list = unzip(z)
    end

    def push_category line
        dir = line.text.sub(%r{^/}, '')
        @dir_list << @dir_list.last.to_pathname.join(dir).to_s
        @dir_indents << line.indent
    end

    def unindented? line
        return line.indent <= @dir_indents.last
    end

    # Array#zipの逆
    def unzip list
      return [] if list.empty?
      size = list.min{|a, b| a.size <=> b.size}.size

      result = Array.new(size){[]}
      list.each do |elm|
        (0 .. (size - 1)).each do |i|
          result[i] << elm [i]
        end
      end
      return result
    end

    def execute lines
      loop do
        line = lines.first
        if !lines.first || lines.first.text =~ /^:/
          save_category
          break
        end


        lines.shift
        if unindented? line
          # インデント解除でディレクトリ指定の終端と解釈する
          save_category
          pop_category line
        end

        if line.text =~ %r{^/}
          # ディレクトリ指定
          save_category
          push_category line
        elsif line.text =~ /^@/
            # ディレクトリ指定を伴わない分類
            # no-operation(インデント数さえ取得できればよいため)
        else
          @keywords << line.text 
        end
      end

      return @dirs.zip(@keywords_list).reject{|e| keywords = e[1]; keywords.empty?}#.tap
    end
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
      #Pixiv::Crawler.new(
      Pixiv::ParallelCrawler.new(
        @keyword,
        @opt
      ).crawl
    end
  end
end

