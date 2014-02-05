# vim:set fileencoding=utf-8:

require 'thread'
require 'pp'

module TkMulti
  @queue = Queue.new
  @mutex = Mutex.new
  @event_thread =nil
  class << self
    public
    def multi(&block)
      #p block
      raise ArgumentError, 'block is required' unless block
      @queue.push block
    end

    private
    def start
      puts 'tkmulti.start'
      @mutex.synchronize {
        next if @event_thread
        @event_thread = Thread.new {
          loop do
            f = @queue.pop
            f.call
          end
        }
      }
    end
  end
end

TkMulti.__send__ :start


