#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

# 試作
require 'fileutils'
require 'csv'
#require_relative 'crawler'
require_relative 'parallel_cralwler'
require_relative '../config'

module Pixiv
  #class UserCrawler < Crawler
  class UserCrawler < ParallelCrawler

    #USER_IDS = [
    #  75969,        # ふんぼ
    #  598527,       # メリット舞踏中
    #  375096,       # うなっち
    #  2370019,      # 秋月ミヤ＠ついった
    #  5209859,      # ぱらがす＠ついったー
    #  3764501,      # 海馬さん@KC(
    #  222280,       # はせ☆
    #  31783,        # YOU_naka
    #  4044738,      # くろ
    #  447167,       # メピカリ
    #  470827,       # 童顔カルピス・con
    #  2886368,      # とらいし666
    #  2834321,      # たちみ
    #  25057,        # もっけ
    #]

    class << self
      extend Forwardable

      # スレッドプールをスーパークラスと共有
      def_delegators(
        :superclass,
        :pool_crawl,
        :pool_child,
        :pool_download
      )

      def crawl_users
        #Pixiv::PictureDb.open do |db|
        #  db = nil # not use mysql

          
          UserData.users do |user|
            crawler = create_user_crawler(user)
            crawler.crawl
          end
          #  UserCrawler.join
          #end
      end

      def create_user_crawler(user)
        crawler = new(
          user.id,      #keyword,
          min_page: 1,
          max_page: 5001,
          r18: false,
          #news_only: false,
          news_only: true,
          #news_save: false,
          news_save: true,
          #db: db,
          parent_dir: 'user',

          user_name: user.name
        )
        return crawler
      end
    end

    def initialize(keyword, opt={})
      @user_name = opt[:user_name]
      super
    end


    def make_dest_dir(keyword, parent_dir, is_r18, noop)
      parent_dir = "" unless parent_dir
      parent_dir = parent_dir.split('/').map{|s| fix_basename(s)}.join('/')

      dir_prefix = is_r18 ? "r18_" : ""
      dest_dir = PIXIV_DIR.join(parent_dir, fix_basename("%s%s_%s" % [dir_prefix, keyword, @user_name]))

      dest_dir.mkpath unless noop || dest_dir.exist?
      return dest_dir
    end

    def index_uri(page)
      h = {
        id: @keyword,
        p: page,
      }
      query = URI.encode_www_form(h)
      return "http://www.pixiv.net/member_illust.php?#{query}"
    end

    def ident_message
      return "user_name='#{@user_name}'"
    end
  end

end

class User < Struct.new(:id, :name); end

class Pixiv::UserCrawler::UserData
  class << self
    include Crawlers::Util
    def init
      FileUtils.touch(SAVE_FILE) unless SAVE_FILE.exist?
    end

    public
    def users(&block)
      raise unless block
      #CSV.open(SAVE_FILE, "r:UTF-8", row_sep: '\r\n') do |csv|
      CSV.open(SAVE_FILE, "r:UTF-8", row_sep: "\n") do |csv|
        csv.flock(File::LOCK_SH)
        csv.reverse_each do |row|
          # コメント行を飛ばす
          next if row[0].strip =~ /^#/ 

          user = User.new
          user.id   = row[0]
          user.name = row[1]
          block.call(user)
        end
      end
    end

    def dirs
      result = []
      users do |user|
        #pp [user.id, user.name]
        result << Pathname('user').join(fix_basename("#{user.id}_#{user.name}"))
      end
      result.select!{|p| Pixiv::PIXIV_DIR.join(p).exist?}
      return result.sort_by!{|p| Pixiv::PIXIV_DIR.join(p).mtime}.reverse!
    end

    public
    #def add_user(id)
    #  user_name = fetch_user_name(id)
    #  puts user_name

    #  # id がすでに登録されていた場合は何もしない
    #  CSV.open(SAVE_FILE, "r:UTF-8") do |csv|
    #    csv.flock(File::LOCK_SH)
    #    csv.each do |row|
    #      user_id = row[0]
    #      return if id == user_id
    #    end
    #  end

    #  CSV.open(SAVE_FILE, "a:UTF-8") do |csv|
    #    csv.flock(File::LOCK_EX)
    #    csv << [id, user_name]
    #  end
    #end

    def add_user(id)
      add_user_list([id])
    end

    def add_user_list(ids)

      existing_ids = nil
      CSV.open(SAVE_FILE, "r:UTF-8", row_sep: "\n", headers: [:id, :name]) do |csv|
        csv.flock(File::LOCK_SH)
        table = csv.readlines
        existing_ids = table[:id]
      end

      # すでに登録されているidを取り除く
      new_ids = ids - existing_ids

      CSV.open(SAVE_FILE, "a:UTF-8", row_sep: "\n") do |csv|
        csv.flock(File::LOCK_EX)

        new_ids.each do |id|
          user_name = fetch_user_name(id)
          puts user_name
          csv << [id, user_name]
        end
      end
    end

    private
    def fetch_user_name(id)
      index_uri = index_uri(id)
      pp index_uri
      doc = Mtk::Net::Firefox.new.get_document(index_uri)
      user_node = doc.at_css('.user')
      raise "not found user_name uri=#{index_uri}" unless user_node

      name_at_place = user_node.text.strip
      name = name_at_place.sub(/[@＠].*$/, '')
      return name.empty? ? name_at_place : name   
    end

    def index_uri(id)
      h = {
        id: id,
      }
      query = URI.encode_www_form(h)
      return "http://www.pixiv.net/member_illust.php?#{query}"
    end
  end

  SAVE_FILE = Crawlers::Config::save_file_of_pixiv_user
  init()
end

if $0 == __FILE__
  Thread.abort_on_exception = true
  tlog('start')
  Pixiv::UserCrawler::crawl_users
  tlog('end')
end

