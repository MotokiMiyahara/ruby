# vim:set fileencoding=utf-8:

require 'pp'
require 'fileutils'

require 'my/my'
require 'mtk/concurrent/thread_pool'
require 'mtk/net/uri_getter'

require_relative 'config'
require_relative 'crawler_m'

# 殆どの板用
module Moeren
  class Crawler
    include Crawler_m
    module Helper
      # example
      #   inverse_hash {:a=>[1, 2, 3], :b=>[10, 20, 30], :c=>[100, 200, 300]}
      #     => {1=>:a, 2=>:a, 3=>:a, 10=>:b, 20=>:b, 30=>:b, 100=>:c, 200=>:c, 300=>:c}
      def self.inverse_hash(hash)
        result = {}
        hash.each_pair do |key, value|
          value.each do |v|
            result[v] = key
          end
        end
        return result
      end
    end


    BOARD_TO_HOST = Helper.inverse_hash({
      "moepic.moe-ren.net" => 
        %w{moeren},
      "moepic2.moe-ren.net" =>
        %w{waren kaberen},
      "moepic3.moe-ren.net" =>
        %w{remodk remod moeura waura dogaura kabeura},
    })

    SUPPORTED_BOARDS = BOARD_TO_HOST.keys


    # -------------------------------------
    def initialize board, pool, opts={}
      @board = board
      @pool = pool

      super opts
    end

    private
    def dest_sub_dir_name
      return @board
    end

    def root_uri
      return "http://#{root_host}/gazo/#{@board}/piclist/index.htm"
    end

    def root_host
      unless BOARD_TO_HOST.has_key? @board
        raise ArgumentError, "not supported board: #{@board}"
      end
      return BOARD_TO_HOST[@board]
    end

    def image_uris(base_uri, html)
      picures = html.scan(%r{<a href="\.\./write\.php\?res=(\d+)">\[(\1.\w+)\]}).map{|e|e.at 1}.uniq.sort.reverse
      return picures.map{|pict| URI.parse(base_uri).merge("../files/#{@board}#{pict}").to_s}
    end

    # 次ページが無い時はnilを返す
    def next_uri(base_uri, html)
      next_uri =  html =~ %r{<a href="([^"]*)"><strong><font color="#ffffff"><{0,2}次>{0,2}</strong></a>} ?
        URI.parse(base_uri).merge($1).to_s : nil
    end

    # ThreadPoolで並行作業
    def push_task(*args, &block)
      @pool.push_task *args, &block
    end
  end
end
