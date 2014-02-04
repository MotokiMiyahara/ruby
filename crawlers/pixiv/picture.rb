# vim:set fileencoding=utf-8:

require 'sequel'
require_relative 'constants'


module Pixiv

  class PictureDb
    #include SQLite3
    DATA_FILE = ::Pixiv::PIXIV_DIR + '_pixiv_crawler.db'

    def self.open &block
      raise ArgumentError unless block_given?
      #Sequel.sqlite(DATA_FILE.to_s) do |db|
      #Sequel.connect('mysql://admin:admin99@localhost/pixiv') do |db|
      Sequel.connect('mysql://admin:admin99@localhost/pixiv', {:encoding=>"utf8"}) do |db|
        instance = new db
        block.call(instance)
      end
    end



    def reset_database
      drop_tables = lambda do 
        [:files, :pictures, ].each do |sym|
          @db.drop_table?(sym)
        end
      end
      drop_tables.call

      # pictures --------
      @db.create_table?(:pictures) do
        primary_key :id
        String :illust_id, index: true, unique: true, size: 191
        String :tags, text: true, size: 1000
        Integer :score_count
      end

      # files ---------
      @db.create_table?(:files) do
        primary_key :id
        foreign_key :picture_id, :pictures
        String :path, text: true
      end
    end

    DEFINE_MODELS = lambda{|db|

      class Picture < Sequel::Model
        class << self
          def order_by_popularity
            order(Sequel.desc(:score_count))
          end
        end

        plugin :force_encoding, 'UTF-8'
        one_to_many :files

        def initialize
          super
          @inserted_at_current_crawl = nil
        end

        # 今回の巡回で挿入された場合true
        def inserted_at_current_crawl?
          return @inserted_at_current_crawl
        end
        def be_inserted_at_current_crawl
          @inserted_at_current_crawl = true
        end
      end

      class File < Sequel::Model
        class << self
        end
        plugin :force_encoding, 'UTF-8'
        many_to_one :picture
      end
    }

    class DummyPicture < Struct.new(:illust_id, :tags, :score_count); end

    def initialize db
      @db = db
      DEFINE_MODELS.call(db)
    end

    public
    def picture
      return Picture
    end

    def insert_picture picture
      @db.transaction do
        return if exist_picture? picture
        picture.save
        picture.be_inserted_at_current_crawl
      end
    end

    def exist_picture? picture
      return 0 < Picture.where(illust_id: picture.illust_id).count
    end

    def insert_file_path picture, path
      return unless picture.inserted_at_current_crawl?
      f = File.new
      f.path = path.relative_path_from(PIXIV_DIR)
      picture.add_file(f)
    end

    def populars keywords, count=nil
      ds = Picture.order(Sequel.desc(:score_count))

      keywords.split(/\s+/).each do |keyword|
        ds = ds.where(Sequel.like(:tags, "%#{keyword}%"))
      end

      ds = ds.limit(count) if count
      return ds
    end

    #    def get_popular_picture_path keywords, count=nil
    #      result = []
    #      populars(keywords, count).each do |pict|
    #        pict.files_dataset.order(:path).each do |file|
    #          result << PIXIV_DIR.join(file.path)
    #        end
    #      end
    #      return result
    #    end
    #  end

    require 'mtk/import'
    def get_popular_picture_path keywords, count=nil
      return populars(keywords, count).flat_map{|pict| pict.files.sort_by(&:path)}.map{|file| PIXIV_DIR.join(file.path)}
    end
  end

  class Popular
    DIR = PIXIV_DIR.join 'popular'
    class << self
      def search *args
        DIR.rmtree if DIR.exist?
        DIR.mkdir
        PictureDb.open do |db|
          path_list = db.get_popular_picture_path(*args)
          path_list.each.with_index do |path, index|
            next unless path.exist?
            base = "%010d_%s" % [index, path.basename]
            link = DIR.join base
            link.make_link path
          end
        end
      end
    end
  end



end

if $0 == __FILE__
  #Pixiv::PictureDb.open do |db|
  #  pp db.get_popular_picture_path 'ピンク'
  #end
  #Pixiv::Popular.search 'レミリア', 100
  #Pixiv::Popular.search '北条響 R-18', 200
  #Pixiv::Popular.search '', 100
  Pixiv::Popular.search 'R-18', 100
end

