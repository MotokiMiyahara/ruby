# vim:set fileencoding=utf-8:

require 'my/config'
require 'pathname'

module Crawlers
  class Config
    USER_CONFIG_DIR = Pathname("#{ENV['HOME']}/.mtk/crawlers/")
    USER_CONFIG_FILE = USER_CONFIG_DIR + "config.rb"

    class << self
      def app_dir
        My::CONFIG.dest_dir.join('crawler')
      end

      def save_dir
        app_dir.join('_save')
      end

      # pixiv guiのでフォルダ内の最後に閲覧した画像のパスを保存するファイル
      def save_file_of_last_shown_image
        save_dir.join('_last_shown_image.sav')
      end

      # Pixiv::UserCrawlerで巡回するユーザの情報の保存ファイル
      def save_file_of_pixiv_user
        save_dir.join('_pixiv_user.csv')
      end

      def keep_dir
        #Pathname('C:/Documents and Settings/mtk/デスクトップ/keep')
        app_dir.join('keep')
      end

      def database_yml
        USER_CONFIG_DIR + ('database.yml')
      end

      # @return :hard_link or :sym_link
      def news_type
        :hard_link
        #:sym_link
      end

      def make_dirs
        save_dir.mkdir unless save_dir.exist?
      end

      def load_user_file
        if USER_CONFIG_FILE.exist?
          puts "loading: #{USER_CONFIG_FILE}"
          load USER_CONFIG_FILE
        end
      end
    end
  end
end

Crawlers::Config::load_user_file


