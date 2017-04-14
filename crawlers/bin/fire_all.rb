#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'active_record'

require 'optparse'
require_relative '../lib/crawlers/parsers'

if $0 == __FILE__
  begin
    Thread.abort_on_exception = true

    opts = {}
    parser = OptionParser.new
    parser.on('-f FILE', 'dsl file'){|v| opts[:file] = Pathname(v).expand_path}
    parser.on('--noop', 'no oparation'){|v| opts[:noop] = true}
    parser.parse!(ARGV)

    Crawlers::Parsers::BootStrapper.new(opts).start

  ensure
    ActiveRecord::Base.connection.close
  end
end

