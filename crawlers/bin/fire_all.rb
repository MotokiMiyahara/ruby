#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'optparse'
require_relative '../parsers'

if $0 == __FILE__
  Thread.abort_on_exception = true

  opts = {}
  parser = OptionParser.new
  parser.on('-f FILE', 'dsl file'){|v| opts[:file] = Pathname(v).expand_path}
  parser.on('--noop', 'no oparation'){|v| opts[:noop] = true}
  parser.parse!(ARGV)

  Crawlers::Parsers::DslParser.new(opts).start
end

