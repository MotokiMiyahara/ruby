# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:
require_relative '../db'
require 'pp'


if $0 == __FILE__
  #Images.connection.execute("TRUNCATE TABLE images;")
  #Images.new(parent_id: 222222, created_at_on_gelbooru: "Mon Sep 08 11:25:39 -0500 2014").save!


  # レコード取得
  pp Images.all
end

