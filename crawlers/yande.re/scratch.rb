# vim:set fileencoding=utf-8:
require 'pathname'
require 'pp'

#pp Pathname.glob('./**')
#
#pp Pathname.new('.').children.
#  </i></a></span><ul class="page-list">
#<li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d">1</a></li><li class="current">2</li>
#<li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=3">3</a>
#</li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=4">4</a></li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=5">5</a></li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=6">6</a></li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=7">7</a></li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=8">8</a></li><li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=9">9</a></li></ul><span class="next"><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=3" rel="next" class="_button" title="次へ"><i class="_icon sprites-next-linked">


#html = '<li><a href="?word=%28%E9%88%B4%E4%BB%99%E3%83%BB%E5%84%AA%E6%9B%87%E8%8F%AF%E9%99%A2%E3%83%BB%E3%82%A4%E3%83%8A%E3%83%90+OR+%E3%81%86%E3%81%A9%E3%82%93%E3%81%92%29&amp;order=date_d&amp;p=3">3</a>'

html = nil
open('a.html', 'r:UTF-8')do |f|
  html = f.read
end

#p html
page = 3
p html =~ %r{<a href="[^"]*p=(#{(page + 1)})[^"]*">\1</a>}o
p $1

unless html =~ %r{<a href="[^"]*p=(#{(page + 1)})[^"]*">\1</a>}o
  p 'aaaaaaaaaaaa'
end

