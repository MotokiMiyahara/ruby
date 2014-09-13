# vim:set fileencoding=utf-8:

require_relative 'crawler_m'
require_relative 'config'
require'my/my'
require'pp'

module Moeren
  class MrCrawler
    include Crawler_m

    def initialize (opts = {})
      super opts
    end

    private
    def root_uri
      return "http://www.nijibox3.com/moeren/uploader/all.html?view=list&order=0"
    end

    def dest_sub_dir_name
      return "mr"
    end

    def image_uris(base_uri, html)
      pictures = html.scan %r{<a href="\./src/([^"]*).html" target="target_blank">\1</a>}
      return pictures.map!(&:first).map!{|pict| "http://www.nijibox3.com/moeren/uploader/src/#{pict}"}
    end
    
    def next_uri *args
      # 1ページのみ
      return nil 
    end

    def push_task *args, &block
      # 同時に複数のダウンロードを行うとアクセス禁止になるため、スレッドを立てない
      block.call
    end
  end
end
