require 'thread'

class Hazetug
  module Ui
    class Basic
      @@mutex ||= Mutex.new

      attr_reader :stdout, :stderr, :stdin

      def initialize(stdout=nil, stderr=nil, stdin=nil)
        @stdout, @stderr, @stdin = (stdout || STDOUT), (stderr || STDERR), (stdin || STDIN)
      end

      def ask(*args, &block)
        @@mutex.synchronize { highline.ask(*args, &block) }
      end

      def say(statement)
        @@mutex.synchronize { highline.say statement }
      end

      def message(message)
        say message
      end

      def error(message)
        @@mutex.synchronize { stdout.puts message }
      end

      private

      def highline
        @highline ||= begin
          require 'highline'
          HighLine.new(@stdin, @stdout)
        end
      end
    end

    class Color < Basic
      attr_reader :color_cache

      def initialize(stdout=nil, stderr=nil, stdin=nil)
        super
        @color_cache = {error: [:bold, :red]}
      end

      def say(statement); super( color(statement, color_cache[:default]) ) ;end
      def error(message); super( color(message, color_cache[:error]) ) ;end

      def color(string, *colors)
        color? ? highline.color(string, *colors) : string
      end

      def colored(key, message)
        color(message.to_s, color_cache[key]) if color?
      end

      def color?
        # make possible turn on/off
        true
      end
    end

    class Default < Color
      def say(statement); super('     ' + statement) ;end
      def error(message); super('     ' + message) ;end
    end

    class Target < Color
      attr_accessor :target

      def say(statement); super("===> #{@target}: " + statement) ;end
      def error(message); super("===> #{@target}: " + message) ;end
    end
  end
end
