# vim:set fileencoding=utf-8:


require_relative '../yande.re/crawler'

class YandereParser

  def initialize parent, pool
    @parent = parent
    @yandere_pool = pool
  end

  public
  def parse lines
    opt = parseOption lines.shift.text
    keywords = shift_keywords lines
    do_crawl opt, keywords
    @parent.parse lines
  end

  private
  def parseOption command
    opt = {}
    parser = OptionParser.new
    parser.on("--type=VAL"){|v|
      case v
      when "new"
        opt[:min_page] = 1
        opt[:max_page] = 5000
        opt[:news_only] = false
        opt[:news_save] = false
      when "renew"
        opt[:min_page] = 1
        opt[:max_page] = 50
        opt[:news_only] = false
        opt[:news_save] = true
      when "append"
        opt[:min_page] = 1
        opt[:max_page] = 100
        opt[:news_only] = true
        opt[:news_save] = true
      end
    }
    parser.parse command.split(/\s+/)
    return opt
  end

  def do_crawl opt, keywords
    keywords.each do |keyword|
      @parent.add_invokers(
        YandereInvoker.new(
          @yandere_pool, 
          keyword,
          opt
        )
      )
    end
  end

  def shift_keywords lines
    keywords = []
    keywords << lines.shift.text until !lines.first || lines.first.text =~ /^:/
    return keywords
  end

  class YandereInvoker
    include Crawlers::Util
    attr_reader :keyword

    def initialize *args
      @args = args
      @yandere_pool = args[0]
    end
      
    def type
      return :yandere
    end

    def search_r18_dir
      return nil
    end

    def invoke
      @yandere_pool.add_producer {|pool|
        Yandere::Crawler.new(
          *@args
        ).crawl
      }
    end
  end
end


