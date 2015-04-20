# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:
Crawlers
====

Overview
WEB上の画像投稿サイトから、画像を自動収集します。


## Usage
1.下記のファイル内容をファイルに保存する。

    `
      ---[sample_dsl.txt]---
      # vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

      # #: コメント
      # /: フォルダ分け(インデントで閉じられたかを判定)
      # @: フォルダ分けを伴わない分類(フォルダ分けの閉じタグとしても機能)

      #:pixiv --type=renew  --max_page=2 --r18=false
      #:pixiv --type=append --max_page=2 --r18=false
      :pixiv --type=new    --max_page=2 --r18=false
        /chars
          /ドラゴンボール
            孫悟空 ドラゴンボール
            ベジータ ドラゴンボール
          
          /ドラえもん
            のび太

        /風景画
          山 風景
          海 風景
    `

## Install


## Author
[MotokiMiyahara](https://github.com/MotokiMiyahara/)

