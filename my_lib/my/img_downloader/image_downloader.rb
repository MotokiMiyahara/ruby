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

require 'pstore'
require 'set'

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
  #THREAD_COUNT_IMAGE_DOWNLOAD = 50
  THREAD_COUNT_IMAGE_DOWNLOAD = 10

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

    db_path = File.expand_path('~/.mtk/crawlers/2ch/ng_list.dat')
    @db = PStore.new(db_path, true)
    @db.transaction do
      @db[:ng_list] ||= Set.new
    end
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
    log text
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
    #lines = text.scan %r{h?ttp://([^<>\r\n]*?\.(?:jpg|bmp|png|gif))}i
    #return lines.map{|line| "http://" + line[0]}
    lines = text.scan %r{(?<!src=")(?<!src="h)h?ttp(s?)://([^<>\r\n]*?\.(?:jpeg|jpg|bmp|png|gif))}i
    urls = lines.map{|line| "http#{line[0]}://#{line[1]}"}
    urls.map!{|url| url.sub(%r{/pinktower.com/}, '/')}
    urls.uniq!
    return urls
  end


  def download_from_urls(urls, dir)
    white_urls = nil
    @db.transaction do
      white_urls = urls - @db[:ng_list].to_a
    end

    image_responces = Parallel.map(white_urls, in_threads: THREAD_COUNT_IMAGE_DOWNLOAD) do |url|
      download_from_url(url, dir)
    end

    ng_list = image_responces.select{|r| r.status == :ng}.map(&:url)
    @db.transaction do
      @db[:ng_list] += ng_list
    end
  end

  def download_from_url(url, dir)
    timeout(TIME_OUT) {
      return do_download_from_url(url, dir)
    }
  rescue *NETWORK_ERRORS => e
    log "#{e.message} (#{e.class}) url=#{url}"
    #add_to_ng_list(url)
    return ImageResponse.new(url, :ng)
  rescue => e
    log "#{e.message} (#{e.class}) url=#{url}"
    if e.instance_of?(RuntimeError) && e.message =~ /^redirection forbidden:/
      # add_to_ng_list(url)
      return ImageResponse.new(url, :ng)
    else
      pp e.backtrace
      return ImageResponse.new(url, :program_error)
    end
  end

  def do_download_from_url(url, dir)
    image = calc_image_path(url, dir)
    if File.exists?(image)
      return ImageResponse.new(url, :exists)
    end

    log url
    body = UriGetter.get_binary(url)
    write_image(image, body)
    FileUtils.touch(image) if File.exists?(image)
    return ImageResponse.new(url, :ok)
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
    log e.message
    return false
  end

  def log(*strs)
    print(strs.join("\n") + "\n")
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

class ImageResponse
  attr_reader :url, :status
  def initialize(url, status)
    @url = url
    @status = status # :ok, :ng, :exists, :program_error
  end
end


if $0 == __FILE__
  invoke
end


