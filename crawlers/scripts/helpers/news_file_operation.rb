#!/usr/bin/env ruby
# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'modules'
require 'optparse'

require_relative '../commons'
require_lib 'util'
require_lib 'pixiv/config'
require_lib 'moeren/config'
require_lib 'yande.re/crawler'
require_lib 'danbooru_clones/gelbooru/config'
require_lib 'danbooru_clones/konachan/config'

module Scripts; end

class Scripts::Helpers::NewsFileOperation
  def execute()

    #type = ARGV[0]
    type = ARGV.shift
    news_dir = case type
  when 'pixiv' 
    Pixiv::NEWS_ROTATE_DIR
  when 'moeren'
    Moeren::Config::NEWS_ROTATE_DIR
  when 'yandere'
    Yandere::NEWS_ROTATE_DIR
  when 'gelbooru'
    Crawlers::DanbooruClones::Gelbooru::Config.news_rotate_dir
  when 'konachan'
    Crawlers::DanbooruClones::Konachan::Config.news_rotate_dir
  else
    raise "wrong type=#{type}"
  end

  should_operate = false
  opt = OptionParser.new
  opt.on('-y', 'say yes'){should_operate = true}
  opt.parse!

  #should_delete ||= say_yes?("Do you want to delete #{news_dir}?")
  should_operate ||= say_yes?(pre_message(news_dir))
  exit unless should_operate

  #Crawlers::Util::clean_up_dir(news_dir)
  operate(news_dir)
  #puts "finish. (#{news_dir})"
  puts post_message(news_dir)
end

def say_yes?(prompt)
  puts prompt + " [yN]"
  line = $stdin.gets
  return line =~ /^y(?:es)?/i 
end


def pre_message(news_dir)
  raise 'not implemented.'
end


def post_message(news_dir)
  raise 'not implemented.'
end

def operate(news_dir)
  raise 'not implemented.'
end
end

if $0 == __FILE__
  include Scripts
  #$script_header(:type)
  #RemveNewsFiles.execute()
end


