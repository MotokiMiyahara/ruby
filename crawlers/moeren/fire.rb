#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require'my/my'
require 'pp'

require 'mtk/concurrent/thread_pool'
require_relative 'crawler'
require_relative 'mr_crawler'
require_relative 'single_process'

module Crawlers
  def self.fire(opts={})
    Thread.abort_on_exception = true

    SingleProcess.with { # 二重起動防止
      pool = Mtk::Concurrent::ThreadPool.new

      # 通常の板 ---
      Moeren::Crawler::SUPPORTED_BOARDS.each do |kind|
        pool.add_producer do 
          Moeren::Crawler.new(kind, pool, opts).crawl
        end
      end

      # アップローダ --- 
      # アクセス制限回避のため、1スレッドでダウンロードを行う
      begin
        Moeren::MrCrawler.new.crawl
      rescue => e
        puts "#{e.message} (#{e.class.name})"
      end

      pool.join
    }
  end
end

if $0 == __FILE__
  Crawlers.fire
end

