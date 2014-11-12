#!/usr/bin/env ruby
# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'optparse'
require 'mtk/util/dir_rotator'

require_relative 'commons'
require_relative 'helpers/news_file_operation'
require_lib 'util'
require_lib 'pixiv/config'
require_lib 'moeren/config'
require_lib 'yande.re/crawler'
require_lib 'danbooru_clones/gelbooru/config'
require_lib 'danbooru_clones/konachan/config'

module Scripts; end

class Scripts::RotateNewsFiles < Scripts::Helpers::NewsFileOperation

  private
  # @Override
  def pre_message(news_dir)
    return "Do you want to rotate #{news_dir}?"
  end

  # @Override
  def post_message(news_dir)
    return "finish rotating. (#{news_dir})"
  end

  # @Override
  def operate(news_dir)
    Mtk::Util::DirRotator.new(news_dir, verbose: false).rotate
  end
end

if $0 == __FILE__
  include Scripts
  script_header(:type)
  RotateNewsFiles.new.execute()
end


