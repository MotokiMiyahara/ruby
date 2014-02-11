#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'optparse'
require_relative '../parsers'

if $0 == __FILE__
  Thread.abort_on_exception = true

  dsl_file = nil
  opt = OptionParser.new
  opt.on('-f FILE', 'dsl file'){|v| dsl_file = Pathname(v).expand_path}
  opt.parse!(ARGV)

  DslParser.new(dsl_file).start
end

