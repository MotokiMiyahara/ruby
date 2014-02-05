# vim:set fileencoding=utf-8:

require 'pp'
require 'uri'

a = URI('http://aaaa/b.png')
a = URI(a)
p a
