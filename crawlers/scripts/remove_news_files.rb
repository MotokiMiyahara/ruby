#!/usr/bin/env ruby
# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'optparse'

require_relative 'commons'
require_relative 'helpers/news_file_operation'
require_lib 'util'
require_lib 'pixiv/config'
require_lib 'moeren/config'
require_lib 'yande.re/crawler'
require_lib 'danbooru_clones/gelbooru/config'
require_lib 'danbooru_clones/konachan/config'

module Scripts; end

class Scripts::RemoveNewsFiles < Scripts::Helpers::NewsFileOperation

  # @Override
  def pre_message(news_dir)
    return "Do you want to delete #{news_dir}?"
  end

  # @Override
  def post_message(news_dir)
    return "finish deleting. (#{news_dir})"
  end

  # @Override
  def operate(news_dir)
    Crawlers::Util::clean_up_dir(news_dir)
  end
end

if $0 == __FILE__
  include Scripts
  script_header(:type)
  RemoveNewsFiles.new.execute()
end


