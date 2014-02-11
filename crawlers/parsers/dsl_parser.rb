# vim:set fileencoding=utf-8:

require 'optparse'
require 'pp'

require 'mtk/concurrent/thread_pool'
require 'mtk/import'
require_relative '../pixiv/picture'

class DslParser
  attr_reader :invokers
  def initialize(file=nil)
    #@file = file || __FILE__.to_pathname.dirname.join("../dsl.txt")
    @file = file || Pathname(__FILE__).dirname.join("../dsl.txt")

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
    open(@file, "r:UTF-8")do |f|
      lines = f.each_line.map{|line| Line.new(line)}.reject{|line| line.blank?}
      parse lines
    end
  end

  #---------------------------
  # :section: toplevel
  #---------------------------

  def parse lines
    return unless lines.first
    case lines.first.text
    when /^:pixiv/
      PixivParser.new(self, @pixiv_db).parse lines
    when /^:yandere/
      YandereParser.new(self, @yandere_pool).parse lines
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

  class Line
    INDENT_OF = {
      ' ' => 1,
    }
    INDENT_OF.default_proc = proc{|k, v| raise NotSupportedSpaceError, "Not supported space-charctor: #{k} #{v}"}


    attr_reader :indent, :text
    def initialize(str)
      @indent = calc_indent str.chomp
      @text = str.sub(/#.*$/, '').strip
    end

    public
    def blank?
      @text.empty?
    end

    private
    def calc_indent str
      str_indent = str.match(/^[\s|　]*/)[0]
      return str_indent.scan(/[\s|　]/).map{|s| INDENT_OF[s]}.inject(0){|sum, a| sum + a}
    end
  end

  class NotSupportedSpaceError < StandardError; end
end


