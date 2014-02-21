#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:
# データ保存用のディレクトリを作るだけ

require_relative 'config'
require_relative 'pixiv/constants'
require_relative 'moeren/config'
require_relative 'yande.re/crawler'
require_relative 'gelbooru/config'

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

    Gelbooru::SITE_DIR,
    Gelbooru::ALL_IMAGE_DIR,
    Gelbooru::NEWS_DIR,
    Gelbooru::SEARCH_DIR,
  ]

  dirs.each do |dir|
    dir.mkpath
  end




  puts 'finished.'
end

if $0 == __FILE__
  main
end
