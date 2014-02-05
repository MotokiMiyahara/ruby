#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require_relative 'parsers'

if $0 == __FILE__
  Thread.abort_on_exception = true
  DslParser.new.start
end

