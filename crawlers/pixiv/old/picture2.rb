# vim:set fileencoding=utf-8:

require 'sqlite3'
require_relative 'constants'


module Pixiv
  class Picture < Struct.new(
      :illust_id,
      :tags,
      :score_count)
  end

  class PictureDb
    include SQLite3
    DATA_FILE = ::Pixiv::PIXIV_DIR + '.pixiv_crawler.db'

    def self.open
      raise ArgumentError unless block_given?
      instance = new
      yield instance
    #rescue Exception => e
    #  pp e.class
    #  pp e.message
    #  pp e.backtrace
    ensure
      instance.close if instance
    end

    def initialize
      is_data_exist = DATA_FILE.exist?

      @db = Database.new(DATA_FILE.to_s)
      create_picture_table unless is_data_exist
    end

    public

    def show_pictures
        stmt = <<-"EOS"
          SELECT * FROM picture
        EOS
        @db.execute(stmt)
    end

    def show_pictures_order_by_popularity
        stmt = <<-"EOS"
          SELECT * FROM picture ORDER BY picture.score_count DESC
        EOS
        @db.execute(stmt)
    end

    def insert_picture picture
      @db.transaction do
        return if exist_picture? picture

        binds = {
          illust_id: picture.illust_id,
          tags: picture.tags.join(' '),
          score_count: picture.score_count
        }
        stmt = <<-"EOS"
          INSERT INTO picture (
            illust_id,
            tags,
            score_count
          ) VALUES (

            :illust_id,
            :tags,
            :score_count
          )
        EOS

        @db.execute(stmt, binds)
      end
    end

    def exist_picture? picture
      binds = {:illust_id => picture.illust_id}
      stmt = <<-"EOS"
        SELECT * FROM picture where picture.illust_id = :illust_id
      EOS
      return @db.execute(stmt, binds).size > 0
    end


    def close
      @db.close
    end

    # -------
    def drop_picture_table
      @db.execute('drop table picture')
    end

    def create_picture_table
      stmt = <<-"EOS"
        create table picture(
          picture_id INTEGER PRIMARY KEY AUTOINCREMENT,
          illust_id STRING UNIQUE,
          tags STRING,
          score_count INT
          )
      EOS
      @db.execute(stmt)
    end

  end
end

if $0 == __FILE__
  Pixiv::PictureDb.open do |db|
    pp db.show_pictures_order_by_popularity 
  end
end

