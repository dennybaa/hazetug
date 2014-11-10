require 'logger'

class Hazetug
  module Logger
    LOGDEVICE ||= STDOUT

    class Logger < ::Logger

      def initialize(*args)
        super(*args)
        instance_formatter
      end

      def msg2str(msg)
        case msg
        when String
          msg
        when Exception
          s = "%s: %s" % [msg.class, msg.message]
          s << (msg.backtrace ? msg.backtrace.map {|x| "\n    #{x}" }.join : "") if show_trace?
          s
        else
          msg.inspect
        end
      end

      private

      def show_trace?
        # fix it 
        true
      end

      def instance_formatter
        self.formatter = proc { |severity, timestamp, progname, msg|
          "%s\n" % msg2str(msg)
        }
      end

    end

    def self.included(base)
      base.class_eval <<-EOP
        def log
          @logger ||= Hazetug::Logger::Logger.new(LOGDEVICE)
        end
      EOP
    end
  end
end
