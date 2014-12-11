#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:
# データ保存用のディレクトリを作るだけ

require_relative '../lib/crawlers/config'
require_relative '../lib/crawlers/pixiv/constants'
require_relative '../lib/crawlers/moeren/config'
require_relative '../lib/crawlers/yande.re/crawler'
require_relative '../lib/crawlers/hentai/config'
require_relative '../lib/crawlers/danbooru_clones/konachan/config'
require_relative '../lib/crawlers/danbooru_clones/gelbooru/config'

def main

  puts "You want to make dir? [Y/n]  (#{Crawlers::Config.app_dir})"
  reply = gets.chomp
  exit unless reply =~ /^Y/i


  dirs = [
    Crawlers::Config.app_dir,
    Crawlers::Config.save_dir,
    Crawlers::Config.keep_dir,

    Pixiv::PIXIV_DIR,
    Pixiv::ALL_IMAGE_DIR,
    Pixiv::NEWS_DIR,
    Pixiv::SEARCH_DIR,

    Moeren::Config::DEST_DIR,
    Moeren::Config::NEWS_DIR,
    Yandere::YANDERE_DIR,
    Yandere::NEWS_DIR,

    Hentai::Config.site_dir,

    *([Gelbooru, Konachan].flat_map{|clazz|
      [
        clazz::Config.site_dir,
        clazz::Config.all_image_dir,
        clazz::Config.news_dir,
        clazz::Config.search_dir,
      ]
    }),
  ]

  dirs.each do |dir|
    dir.mkpath
  end

  puts 'finished.'
end

if $0 == __FILE__
  include Crawlers::DanbooruClones
  main
end
