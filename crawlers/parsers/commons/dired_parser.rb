# vim:set fileencoding=utf-8:

require_relative 'modules'
require_relative '../../util'

require 'pathname'
require 'pp'

require_relative 'line'

module Crawlers::Parsers::Commons
  class DiredParser
    def initialize
      @keywords = []
      @stack = [Info.new(indent: -1, categories: [])]
      @items = []
    end

    public
    def parse lines
      loop do
        line = lines.first
        if !lines.first || lines.first.text =~ /^:/
          save_category
          break
        end


        lines.shift
        if unindented?(line)
          # インデント解除でディレクトリ指定の終端と解釈する
          save_category
          pop_category(line)
        end

        if line.text =~ %r{^/}
          # ディレクトリ指定
          save_category
          push_category(line)
        elsif line.text =~ /^@/
          # ディレクトリ指定を伴わない分類
          # no-operation(インデント数さえ取得できればよいため)
        else
          @keywords << line.text 
        end
      end

      return @items
      #return @dirs.zip(@keywords_list).reject{|e| keywords = e[1]; keywords.empty?}#.tap
    end

    private
    def save_category
      return if @keywords.empty?

      info = @stack.last
      @keywords.each do |keyword|
        @items << Item.new(info.categories, keyword)
      end
      @keywords = []
    end

    def pop_category(line)
      @stack.reject!{|info| line.indent <= info.indent}
    end

    def push_category(line)
      last_info = @stack.last
      basename = line.text.sub(%r{^/}, '')

      categories = last_info.categories + [basename]
      @stack << Info.new(indent: line.indent, categories: categories)
    end

    def unindented?(line)
      return line.indent <= @stack.last.indent
    end

    class Info
      attr_reader :indent, :categories
      def initialize(indent:, categories: [])
        @indent = indent
        @categories = categories.dup.freeze
      end
    end

    class Item
      attr_reader :keyword, :categories
      def initialize(categories, keyword, dir_basename: keyword)
        @categories = categories.dup.freeze
        @keyword = keyword.dup.freeze
        @dir_basename = dir_basename
      end

      def dir
        names = @categories + [@dir_basename]
        names.reject!(&:empty?)
        names.map!{|name| Crawlers::Util::fix_basename(name)}
        return Pathname(names[0]).join(*names[1..-1])
      end

      def inspect
        "d=#{dir}"
      end

      private
    end

  end
end


if $0 == __FILE__
  include Crawlers::Parsers::Commons

  lines = Line::parse_file('dsl.txt')
  while lines.first
    pp DiredParser.new.parse(lines)
    lines.shift if lines.first
  end
end

