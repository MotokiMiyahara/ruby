#!/usr/bin/env ruby
# vim:set fileencoding=utf-8:

require 'uri'
require 'net/http'
require 'pathname'
require 'open-uri'
require 'fileutils'
require 'optparse'

require 'resolv-replace'
require 'timeout'

require 'mtk/net/uri_getter'
require 'mtk/concurrent/thread_pool'
require 'my/config'

#require_relative './clipboard'

require 'clipboard'
require 'parallel'

#require_relative '../my'

class MyDownloader
  include Mtk::Net

  USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"
  DEST_DIR = My::CONFIG::dest_dir + 'crawler/2ch'

  TIME_OUT = 10
  THREAD_COUNT_IMAGE_DOWNLOAD = 50

  NETWORK_ERRORS = [
      TimeoutError,
      SocketError, 
      OpenURI::HTTPError,
      Errno::ECONNRESET,
      Errno::EHOSTUNREACH,
  ].freeze

  private
  def initialize
    DEST_DIR.mkdir unless DEST_DIR.exist?
  end

  public
  def download_from_clipborad
    text = Clipboard.paste
    download_from_text(text)
  end

  def download_from_argf
    download_from_text(ARGF.read)
  end

  private
  def download_from_text(text)  
    puts text
    lines = text.split(/\r?\n/)
    lines.each{|line| line.sub!(/#.*$/, '')}
    lines.each{|line| line.strip!}
    lines.reject!(&:empty?)

    urls = lines.find_all{|line| is_uri?(line)}
    download_from_thread_urls(urls)
  end

  def download_from_thread_urls(urls)
    urls.each do |url|
      download_from_thread_url(url)
    end
  end
  
  def download_from_thread_url(url)
    text = UriGetter.get_html_as_utf8(url)
    download_from_doc(text)
  end
  public :download_from_thread_url

  def download_from_doc(text)
    title = extract_title(text)
    p title
    urls = extract_image_urls(text)

    dir = DEST_DIR.join(fix_basename(title))
    dir.mkdir unless dir.exist?

    download_from_urls(urls, dir)
  end

  def extract_title(text)
    if text =~ %r{<title>([^>]+)</title>}
      return $1.strip
    else
      return "unkown"
    end
  end

  def extract_image_urls text
    lines = text.scan %r{h?ttp://([^<>\r\n]*?\.(?:jpg|bmp|png|gif))}i
    return lines.map{|line| "http://" + line[0]}
  end


  def download_from_urls(urls, dir)
    Parallel.each(urls, in_threads: THREAD_COUNT_IMAGE_DOWNLOAD) do |url|
      download_from_url(url, dir)
    end
  end


  def download_from_url(url, dir)
    timeout(TIME_OUT) {
      do_download_from_url(url, dir)
    }
  rescue *NETWORK_ERRORS => e
    puts "#{e.message} (#{e.class}) url=#{url}"
  rescue => e
    puts "#{e.message} (#{e.class})"
    pp e.backtrace
  end

  def do_download_from_url(url, dir)
    image = calc_image_path(url, dir)
    return if File.exists?(image)

    puts url
    body = UriGetter.get_binary(url)
    write_image(image, body)
    FileUtils.touch(image) if File.exists?(image)
  end

  def calc_image_path url, dir
    image = url.split('/')[-1]
    return dir.join(image)
  end

  def write_image file, body
    open(file, "wb") do |f|
      f.write(body)
    end
  end

  def fix_basename basename
    result = basename.dup
    result.gsub!(%r{[\\/:*?"<>|]}, '')
    result.gsub!(/\s|　/, '_')
    return result
  end



  def is_uri? str
    uri = URI(str)
    return  uri.is_a?(URI::HTTP)  ||
    uri.is_a?(URI::HTTPS) ||
    uri.is_a?(URI::FTP) 

  rescue URI::Error => e
    puts e.message
    return false
  end

end


def invoke  
  Thread.abort_on_exception = true

  opt = {}
  parser = OptionParser.new
  parser.on('-c'){|v| opt[:from_clipboard] = true} 
  parser.parse!(ARGV)

  m = MyDownloader.new
  if(opt[:from_clipboard])
    m.download_from_clipborad
  elsif ARGV[0] =~  %r{https?://[\w\d\./]+/}
    m.download_from_thread_url(ARGV[0])
  else
    m.download_from_argf
  end
end



if $0 == __FILE__
  invoke
end

