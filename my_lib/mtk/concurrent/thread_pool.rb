# vim:set fileencoding=utf-8:

require 'mtk/concurrent/thread_pool/half_pool'
#require 'mtk/concurrent/thread_pool/single'

module Mtk
  module Concurrent
    # Usage
    # 
    # pool = ThreadPool.new
    # pool.add_producer do |p|
    #   p.push_task do
    #     # 時間のかかる処理
    #     hevy_work
    #   end
    # end
    # pool.join
    #
    #
    class ThreadPool
      #def initialize(num_consumers)
      def initialize(opts={})
        
        opts[:max_producer_count] ||= 5
        opts[:max_consumer_count] ||= 50

        @producer_pool = HalfPool.new(
          max_worker_count: opts[:max_producer_count],
          size: :infinity,
        )

        @consumer_pool = HalfPool.new(
          max_worker_count: opts[:max_consumer_count],
          size: :infinity,
        )
      end

      public
      def push_consumer_task(&block)
        raise ArgumentError "block is required." unless block_given?
        @consumer_pool.push_task(&block)
      end
      alias :push_task :push_consumer_task

      def add_producer(&block)
        @producer_pool.push_task(self, &block)
      end

      def join
        @producer_pool.join
        @consumer_pool.join
      end
    end
  end
end


#ThreadPool = Mtk::Concurrent::ThreadPool
#Mtk::Concurrent::ThreadPool.new
