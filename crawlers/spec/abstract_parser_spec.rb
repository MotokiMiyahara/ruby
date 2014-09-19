# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:
require 'spec_helper'
require 'crawlers/parsers/boot_strapper'
require 'crawlers/parsers/danbooru_clones/core/test_abstract_parser'
require 'crawlers'

require 'pp'

module Crawlers::Parsers::DanbooruClones::Core
  describe AbstractParser do
    subject(:dirs){@data.items.map(&:dir).map{|p| p.to_s}}
    subject(:keywords){@data.items.map(&:keyword)}

    context 'shift: empty, all: empty' do
      before :each do
        @data = parse('1.txt')
      end
      it 'dirs' do
        expect(dirs).to eq ['chars/alice/alice', 'chars/bob/bob_solo']
      end

      it 'keywords' do
        expect(keywords).to eq ['alice', 'bob solo']
      end
    end


    context 'shift: empty, all: full' do
      before :each do
        @data = parse('2.txt')
      end
      it 'dirs' do
        expect(dirs).to eq ['chars/alice/alice_-ratingsafe_-photo_-animated', 'chars/bob/bob_solo_-ratingsafe_-photo_-animated']
      end

      it 'keywords' do
        expect(keywords).to eq ['alice -rating:safe -photo -animated', 'bob solo -rating:safe -photo -animated']
      end
    end


    context 'shift: full, all: empty' do
      before :each do
        @data = parse('3.txt')
      end
      it 'dirs' do
        expect(dirs).to eq ["chars/alice/alice_a", "chars/alice/alice_b_-a", "chars/alice/alice_c_-b_-a", "chars/alice/alice_-c_-b_-a", "chars/bob/bob_solo"]
      end

      it 'keywords' do
        expect(keywords).to eq ['alice a', 'alice b -a', 'alice c -b -a', 'alice -c -b -a', 'bob solo']
      end
    end

    context 'shift: full, all: full' do
      before :each do
        @data = parse('4.txt')
      end
      it 'dirs' do
        expect(dirs).to eq ["chars/alice/alice_a_x_y", "chars/alice/alice_b_-a_x_y", "chars/alice/alice_c_-b_-a_x_y", "chars/alice/alice_-c_-b_-a_x_y", "chars/bob/bob_solo_x_y"]
      end

      it 'keywords' do
        expect(keywords).to eq ['alice a x y', 'alice b -a x y', 'alice c -b -a x y', 'alice -c -b -a x y', 'bob solo x y']
      end
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

