# vim:set fileencoding=utf-8:

require 'thread'
require 'thwait'
require 'monitor'

#  ubuntu 13.10 + ruby2.1で動作させたとき、
# sizeを:infinityにしないとデッドロックする模様
#   -> デフォルト値を size: :infinityに変更

module Mtk
  module Concurrent
    #class ThreadPool
      class HalfPool
        #def initialize(opts={})
        #  max_worker_count = opts[:max_worker_count] 
        #  raise ArgumentError unless max_worker_count

        #  def_opts = {
        #    sized: true
        #  }
        #  opt = def_opts.merge(opts)

        #  case opt[:size]
        #  when :infinity
        #    @queue = Queue.new
        #  when Integer
        #    @queue = SizedQueue.new(opt[:size])
        #  when nil, false
        #    queue_size = max_worker_count * 5
        #    @queue = SizedQueue.new(queue_size)
        #  else
        #    raise
        #  end

        #  @monitor = Monitor.new
        #  @workers = []                         # Guarded by @monitor
        #  @max_worker_count = max_worker_count  # Guarded by @monitor 
        #end
        
        def initialize(
            max_worker_count: nil,
            size: :infinity,
            priority: Thread.current.priority)
          raise ArgumentError unless max_worker_count

          case size
          when :infinity
            @queue = Queue.new
          when Integer
            @queue = SizedQueue.new(size)
          else
            raise
          end

          @monitor = Monitor.new
          @workers = []                         # Guarded by @monitor
          @max_worker_count = max_worker_count  # Guarded by @monitor 
          @priority = priority
        end

        public
        def push_task(*args, &block)
          raise ArgumentError "block is required." unless block_given?
          add_worker_thread_if_needs
          @queue.enq([args, block])
        end

        def join
          end_task
          join_workers
          clear_queue
        end

        private
        def end_task
          @queue.enq(nil)
        end

        def join_workers
          ThreadsWait.all_waits(*@workers)
        end

        def clear_queue
          @queue.deq(true)
        end

        def add_worker_thread_if_needs
          @monitor.synchronize {
            return if  @max_worker_count <= @workers.size
            worker = Thread.new do
              loop {
                  elm = @queue.deq
                  if elm.nil?
                    @queue.enq(nil)
                    break
                  else
                    args, block = *elm
                    block.call(*args) # work
                  end
              }
            end
            worker.priority = @priority
            #puts "#{@priority} priority=#{worker.priority}"
            @workers << worker
          }
        end
      end
  end
end

Mtk::Concurrent::HalfPool::DUMMY = Object.new
class << Mtk::Concurrent::HalfPool::DUMMY
  public
    def push_task(*args, &block)
      raise ArgumentError "block is required." unless block_given?
      block.call(args)
    end

    def join
      # no-operation
    end
end
