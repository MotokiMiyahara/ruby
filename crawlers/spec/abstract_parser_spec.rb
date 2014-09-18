# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:
require 'spec_helper'
require 'crawlers/parsers/boot_strapper'
require 'crawlers/parsers/danbooru_clones/core/test_abstract_parser'
require 'crawlers'

require 'pp'

module Crawlers::Parsers::DanbooruClones::Core
  describe AbstractParser do
    it 'making test' do

      data = parse('konachan.txt')

      pp data.items

      #expect(Crawlers::VERSION).not_to be nil
    end

    def parse(file)
      return TestAbstractParser.parse(dsl(file))
    end

    def dsl(file)
      return File.expand_path(file, File.join(__dir__, 'dsl'))
    end
  end
end


if $0 == __FILE__

end

