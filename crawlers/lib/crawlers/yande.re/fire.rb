#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'pp'
require_relative 'crawler'
require 'mtk/concurrent/thread_pool'

if $0 == __FILE__
  Thread.abort_on_exception = true

  pool = Mtk::Concurrent::ThreadPool.new(
    max_producer_count: 3,
    max_consumer_count: 5)

  # 初回ダウンロード
  new_keywords = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    pussy
  EOS

  new_keywords.each do |keyword|
    pool.add_producer {
      Yandere::Crawler.new(
        pool, 
        keyword,
        min_page: 1,
        max_page: 5000,
        news_mode: false
      ).crawl
    }
  end


=begin
  # 巡回設定
  append_keywords = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    breasts -topless -pussy
    skirt_lift
    panty_pull
    shirt_lift
    torn_clothes
    pussy
    waitress
    topless
  EOS

  append_keywords.each do |keyword|
    pool.add_producer {
     Yandere::Crawler.new(
        pool, 
        keyword,
        min_page: 1,
        max_page: 100,
        news_mode: true
      ).crawl
    }
  end
=end

  pool.join
end

__END__
