# vim:set fileencoding=utf-8:

require 'my/config'

module Crawlers
  class Config
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

      def make_dirs
        save_dir.mkdir unless save_dir.exist?
      end

    end
  end
end



