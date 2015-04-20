Crawlers
====

Overview
WEB上の画像投稿サイトから、画像を自動収集します。


## Usage
1. 下記のファイル内容をファイルに保存する。

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

2. 下記のコマンドを実行する
          ruby crawlers/bin/fire_all.rb -f sample_dsl.txt

3.  インストール時に指定した画像保存ディレクトリ下のpixiv/search/下に画像が保存される。


## Install
1. my_libにパスを通す
         RUBYLIB=path/to/this/ruby/mylib

2. 依存するgemをインストール(crawlers/crawlers.gemspecを参照)

3. 画像保存ディレクトリをプログラムに設定
         # vim:set fileencoding=utf-8:

         require 'pathname'

         # monkey patching
         class Crawlers::Config
           class << self
             def app_dir
               return Pathname('/home/xxxx/generated_data/crawlers')
             end
           end
         end
    
4. 画像保存ディレクトリを作成

`ruby crawlers/bin/installer_crawlers.rb`

## Author
[MotokiMiyahara](https://github.com/MotokiMiyahara/)

