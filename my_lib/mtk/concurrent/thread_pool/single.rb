# vim:set fileencoding=utf-8:

module Mtk
  module Concurren
    class ThreadPool
      # シングルスレッドで動作する
      SINGLE = Object.new
      class << SINGLE
        def initialize
          @producer_pool = HalfPool.new(1, size: 1)
        end

        public
        def push_consumer_task(&block)
          raise ArgumentError "block is required." unless block_given?
          block.call
        end
        alias :push_task :push_consumer_task

        def add_producer(&block)
          @producer_pool.push_task(self, &block)
        end

        def join
          @producer_pool.join
        end
      end
    end
  end
end


