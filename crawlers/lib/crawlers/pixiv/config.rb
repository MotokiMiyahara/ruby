# vim:set fileencoding=utf-8:

require_relative '../config'
require_relative '../errors'
require 'uri'
require 'pp'


module Pixiv
  PIXIV_DIR     = Crawlers::Config::app_dir + 'pixiv'
  NEWS_DIR      = PIXIV_DIR + "news"
  SEARCH_DIR    = PIXIV_DIR + "search"
  USER_DIR      = PIXIV_DIR + "user"
  ALL_IMAGE_DIR = PIXIV_DIR + "_all_images"
end

module Pixiv
  class Config
    class << self

      # 画像uriから保存すべきパスを取得する
      # さらに親ディレクトリがなければ、作成する
      def regular_image_pathname_from_uri(uri)
        uri = URI.parse(uri) if uri.is_a?(String)
        path = uri.path
        basename = path.split('/')[-1]
        illust_id = basename.match(/^(\d+)/).to_a[1]
        unless illust_id
          pp [uri, basename]
          raise Crawlers::DataSourceError, "Can't determin regular_file uri=#{uri} basename=#{basename}"
        end


        filename = 'pixiv_' + basename

        # illust_idから分割用フォルダを計算
        padded_illust_id = '%015d' % illust_id
        #partition_dirs = padded_illust_id.chars.each_slice(3).map{|ds|ds.join}.to_a[0..-2].join('/')
        partition_dirs = padded_illust_id.chars.each_slice(3).map{|ds|ds.join}.to_a[0..-1].join('/')
        path = ALL_IMAGE_DIR.join(partition_dirs, filename)
        path.parent.mkpath unless path.parent.exist?
        return path
      end
    end
  end
end

#Pixiv::Config.regular_image_path('http://www.pixiv.net/member_illust.php?mode=manga_____big&illust_id=40813334&page=1')
#puts Pixiv::Config.regular_image_path_from_uri('http://i2.pixiv.net/img110/img/santarara/40813334_big_p1.png')

