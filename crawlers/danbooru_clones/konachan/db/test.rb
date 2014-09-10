# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:
require_relative '../db'
require 'pp'


if $0 == __FILE__
  #KonachanImages.connection.execute("TRUNCATE TABLE konachan_images;")
  #KonachanImages.new(o_id: 1234).save!

  # レコード取得
  pp KonachanImages.all
end

