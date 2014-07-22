# vim:set fileencoding=utf-8 ts=2 sw=2 sts=2 et:

# rubyの実行環境をenv.txtに保存
# rubyw.exeの調査用に作成
require 'rbconfig'
require 'pp'

if $0 == __FILE__
  OUT_FILE = File.join(__dir__, 'env.txt')
  open(OUT_FILE, 'w:UTF-8') do |f|
    #f.puts RbConfig::CONFIG.pretty_inspect
    f.puts STDOUT.pretty_inspect
  end
end

