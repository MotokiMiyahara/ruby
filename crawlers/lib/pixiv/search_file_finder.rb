# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require 'pathname'
require 'uri'
require 'cgi'
require 'pp'

require_relative 'config'

module Pixiv

  # SearchFileをネットワーク接続無しに探します。
  # @note 
  #    Pixivのファイルの命名規則に依存するため
  #   Pixivの仕様が変わった場合には変更する必要があるかもしれません
  class SearchFileFinder
    EXTENSIONS = %w{
      .jpg .JPG .jpeg .JPEG
      .png .PNG
      .gif .GIF
    }

    def initialize(dir)
      @dir = Pathname(dir)
    end

    public 
    # @return [Pathnam] 見つかったSearchFile
    # @return [nil]     SearchFileが存在しないとき
    def find_by_illust_id(illust_id)
      basenames = %W{
        pixiv_#{illust_id}
        pixiv_#{illust_id}_big_p0
      }

      filenames = basenames.product(EXTENSIONS).map(&:join)
      pathes = filenames.map{|filename| @dir.join(filename)}
      search_file = pathes.detect(&:exist?)
      return search_file
    end

    public
    def find_by_uri(uri)
      illust_id = extract_illust_id_from_uri(uri)
      return nil unless illust_id
      return find_by_illust_id(illust_id)
    end

    private
    def extract_illust_id_from_uri(uri)
      uri = URI(uri)
      params =  CGI.parse(uri.query)
      return params['illust_id'].to_a[0]
    end
  end

end


if $0 == __FILE__
  # test
  dir = Pixiv::SEARCH_DIR.join('東方Project/八雲藍')
  pp Pixiv::SearchFileFinder.new(dir).find_by_uri('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=17813097')
end

