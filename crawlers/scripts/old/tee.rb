# vim:set fileencoding=utf-8:

require_relative 'commons'
require_relative '../util'

if $0 == __FILE__
  gets
  include Scripts
  script_header(:script_file)

  script_file = ARGV[0]
  log_file = Pathname(script_file).dirname.join("out.log")
  out = Crawlers::Util::dos('ruby', *ARGV) 
  #out = Crawlers::Util::dos('rubyw', *ARGV) 
  puts out
  File.write(log_file, out, nil, encodeing: 'UTF-8')
end


