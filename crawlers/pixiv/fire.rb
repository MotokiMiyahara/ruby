# vim:set fileencoding=utf-8:

require 'pp'
require_relative 'crawler'
require_relative 'picture'

require 'mtk/concurrent/thread_pool'
require 'mtk/import'

def new_crawl db
    #(ピンクは淫乱 OR 淫乱ピンク)
  # 初回ダウンロード
  new_keywords = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    後背位
  EOS

  new_keywords.each do |keyword|
    Pixiv::Crawler.new(
      keyword,
      min_page: 1,
      max_page: 1,
      #max_page: 5001,
      r18: false,
      #news_mode: false,
      news_only: false,
      news_save: false,
      db: db,
      #dir: 'アイドルマスターシンデレラガールズ',
    ).crawl
  end
end

def append_crawl db
  # 巡回設定
  append_keywords = <<-EOS.split("\n").map(&:strip).reject(&:empty?)
    極上の貧乳
  EOS

  append_keywords.each do |keyword|
    pp keyword
    Pixiv::Crawler.new(
      keyword,
      min_page: 1,
      max_page: 100,
      r18: false,
      #news_mode: true,
      news_only: true,
      news_save: true,
      db: db
    ).crawl
  end
end



if $0 == __FILE__
  Thread.abort_on_exception = true


tlog('start')
  Pixiv::PictureDb.open do |db|
    #new_crawl db
    append_crawl db
  end
  Pixiv::Crawler.join

tlog('end')
end


__END__

    (鈴仙・優曇華院・イナバ OR うどんげ)
    (島風 OR ぜかまし)
    鼠蹊部
    因幡てゐ
    けしか藍
    小悪魔
    サニーミルク
    スターサファイア
    高級感溢れる羽
    フランドール・スカーレット
    ルーミア
    たまも
    忍野忍
    大婆様
    マコト ブレイブルー
    エリーン
    目がハート
    火焔猫燐
    九重椿
    ハインリーケ・プリンツェシン・ツー・ザイン・ウィトゲンシュタ
    レミリア・スカーレット
