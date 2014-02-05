
#require 'open-uri'
require 'fileutils'

=begin
open("http://iup.2ch-library.com/i/i0923188-1369493856.png") do |src|
#http://bugs.ruby-lang.org/projects/rurema/wiki/ReleasePackageHowTo
#open("http://bugs.ruby-lang.org/themes/ruby-lang/images/ruby-logo.png") do |src|
#open("http://bugs.ruby-lang.org/projects/rurema/wiki/ReleasePackageHowTo") do |src|
  open("a.png", "wb") do |dst|
    dst.write(src.read())
  end
end

=end

require 'uri'
require 'net/http'
url = 'http://iup.2ch-library.com/i/i0923188-1369493856.png'
#url = 'http://bugs.ruby-lang.org/themes/ruby-lang/images/ruby-logo.png'
#

module MyDownloader
  USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"

  private
  def self.get url
    uri = URI(url)
    puts "host: " + uri.host
    puts "path: " + uri.path
    puts "port: " + uri.port.to_s
    http = Net::HTTP.new(uri.host, uri.port) 
    response = http.get(
      uri.path,
      "user-agent" => USER_AGENT_FIREFOX
    ) 
    return response.body
  end
    
  url = 'http://iup.2ch-library.com/i/i0923188-1369493856.png'
  body = get(url)
  open("a.png", "wb") do |file|
    file.write(body)
  end

end

