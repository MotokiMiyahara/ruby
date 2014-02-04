# vim:set fileencoding=utf-8:

module Mtk
  module Util
    module TimeLogger
      class << self
        def instance
          return Thread.current[:"Mtk:Util::TimeLogger::KEY_INSANCE"] ||= Logger.new
        end
        def log *args
          instance.log(*args)
        end

        class Logger
          def initialize
            @previous_time = Time.now
          end
          def log text = ''
            current_time = Time.now
            sec = current_time - @previous_time
            puts "#{text}: #{format(sec)}"
            @previous_time = current_time
          end
          def format(total_sec)
            v = total_sec
            v, sec = v.divmod(60)
            hour, min = v.divmod(60)

            return "%f sec  (%d:%02d:%02d)" % [total_sec, hour, min, sec]

          end
        end

      end

      def tlog *args
        TimeLogger.log(*args)
      end
    end
  end
end

include Mtk::Util::TimeLogger


