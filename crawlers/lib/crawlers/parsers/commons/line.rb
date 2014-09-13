# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'modules'

module Crawlers::Parsers::Commons

  class Line
    INDENT_OF = {
      ' ' => 1,
    }
    INDENT_OF.default_proc = proc{|k, v| raise NotSupportedSpaceError, "Not supported space-charctor: #{k} #{v}"}

    class << self
      def parse_file(file)
        open(file, "r:UTF-8")do |f|
          lines = f.each_line.map{|line| Line.new(line)}.reject{|line| line.blank?}
          return lines
        end
      end
    end

    attr_reader :indent, :text
    def initialize(str)
      @indent = calc_indent(str.chomp)
      @text = str.sub(/#.*$/, '').strip
    end

    public
    def blank?
      @text.empty?
    end

    private
    def calc_indent str
      str_indent = str.match(/^[\s|　]*/)[0]
      return str_indent.scan(/[\s|　]/).map{|s| INDENT_OF[s]}.inject(0, &:+)
    end

    class NotSupportedSpaceError < StandardError; end
end

end

