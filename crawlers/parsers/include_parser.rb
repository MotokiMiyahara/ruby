# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'forwardable'
require 'optparse'
require_relative '../modules'

module Crawlers::Parsers
  class IncludeParser
    extend ::Forwardable
    def_delegators(:@parent, :add_invoker)

    def initialize(parent, parent_file, **opts)
      @parent = parent
      @parent_file = parent_file
      @opts = opts
    end

    def parse(lines)
      files = parseCommandLine(lines.shift.text)
      files.each do |file|
        opts = @opts.merge({
          file: file,
        })
        Crawlers::Parsers::DslParser.new(self, opts).parse_file
        @parent.parse(lines)
      end
    end

    def parseCommandLine(command)
      args = command.split(/\s+/)[1..-1]
      files = args.map{|f| @parent_file.dirname.join(f)}
      raise ArgumentError, "':include' needs included files" if files.empty?
      return files
    end
  end

end





