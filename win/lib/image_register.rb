# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

require_relative 'db'
require 'csv'
require 'pp'

class ImageRegister
  class << self
    CSV_OPTS = {
      encoding: Encoding::UTF_8,
      row_sep: "\r\n",                          # 行区切り
      headers: [:path, :md5]
    }.freeze

    def regist(file)
      #text = ARGF.read.force_encoding('SJIS').encode('UTF-8')
      text = File.read(file, encoding: 'SJIS')
      text.sub!(/^.*\r?\n/, '')
      table = CSV.parse(text, CSV_OPTS)
      Db.new.regist_images(table)
    end
  end
end

if $0 == __FILE__
  #Register::regist
end
