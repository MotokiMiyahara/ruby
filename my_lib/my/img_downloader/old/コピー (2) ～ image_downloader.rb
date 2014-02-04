


require 'uri'
require 'net/http'

class MyDownloader
  USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows NT 5.1; rv:21.0) Gecko/20100101 Firefox/21.0"
  DEST_DIR = "./dest/"

  private_class_method :new

  private
  def initialize
    #@threads = []
    @pile = Workpile.new(100)
  end

  public
  def self.open *args, &block
    m = new
    m.__send__(:do_and_join, *args, &block)
  end
  
  def download_from_text_url url
    text = get(url)
    download_from_text text
  end



  private
  def download_from_text text
    urls = extract_image_urls text
    #urls.each {|e| p e}
    download_from_urls urls
  end

  def extract_image_urls text
    lines = text.scan %r{h?ttp://([^<>\r\n]*?\.(?:jpg|bmp|png|gif))}i
    return lines.map{|line| "http://" + line[0]}
  end


  def download_from_urls urls
    urls.each do |url|
      image = calc_image_path url
      next if File.exists?(image)

      with_thread do
        download_from_url url
      end
    end
  end
  def download_from_url url

puts url
    image = calc_image_path url
    body = get(url)
    write_image(image, body)
  end

  def get(url)
    uri = URI(url)

    #puts "host: " + uri.host
    #puts "path: " + uri.path
    #puts "port: " + uri.port.to_s
    #puts uri

    http = Net::HTTP.new(uri.host, uri.port) 
    response = http.get(
      uri.path,
      "user-agent" => USER_AGENT_FIREFOX
    ) 
    return response.body
  end

  def calc_image_path url
    image = url.split('/')[-1]
    file = File.join(DEST_DIR, image)
    return file
  end

  def write_image file, body
    open(file, "wb") do |f|
      f.write(body)
    end
  end


  private
  def do_and_join 
    yield self
  ensure
    @pile.end_task
    @pile.join
=begin
    @threads.each do |t|
      begin
        t.join
      rescue Exception => e
        puts e.message
      end
    end
=end
  end

  def with_thread *args, &block
    @pile.push_task *args, &block
  end
end



def test  
  #url1 = 'http://iup.2ch-library.com/i/i0923188-1369493856.png'
  #url2 = 'http://danbooru.donmai.us/data/d1fc7a7f2bf17bb6be7c5cbd8681ac31.jpg'
  #urls = [url1, url2]

  MyDownloader.open do |m|
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1317989234/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1368801260/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1359823680/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1361606254/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1307887442/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1365704685/'
    #m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1335794379/'
    m.download_from_text_url 'http://pele.bbspink.com/test/read.cgi/ascii2d/1300030057/'
  end
end

require 'thread'
class Workpile
  def initialize(num_workers)
    @queue = Queue.new
    @workers = []

    @mutex = Mutex.new
    @is_terminating = false # guarded by @mutex

#=begin
    # Spawn worker threads
    num_workers.times do |i|
      @workers << th = Thread.new do
        #puts "Worker #%d is ready." % i

        until @is_terminating
          f = @queue.pop
          if f.nil?
            @mutex.synchronize {
              @is_terminating = true
            }
          else
            f.call # work
            #puts " (#%d)" % i
          end

        end
        #puts "Worker #%d is end. %s" % [i, th]
      end
#=end

    end
  end

  def push_task(&block)
    @mutex.synchronize {
      return if @is_terminating
    }
    @queue.push block
    #@workers.list.sort_by{rand}.each{|worker| worker.run} # wake up!
    #@workers.each{|worker| worker.run} # wake up!
  end

  def end_task
    @queue.push(nil)
  end

#=begin
  def start
    while input = gets.chomp
      break if input == 'exit'
      input.split('').each do |i|
        push_task{print i}
      end
    end
  end

  def join
    @workers.each do |th|
      #puts "#{th}, #{Thread.current}"
      begin
        th.join
      rescue Exception => e
        raise e if e.message =~ /\bDeadlock\b/
        puts e
      end
    end
  rescue Exception => e
        puts e
  end

end


#Workpile.new(100).test

test



