class Hazetug
  class UI
    module Mixin
      def self.included(includer)
        includer.class_exec do
          define_method(:ui) {Hazetug::UI.instance}
        end
      end
    end

    attr_reader :stdout
    attr_reader :stderr
    attr_reader :stdin

    def initialize(stdout, stderr, stdin)
      @stdout, @stderr, @stdin = stdout, stderr, stdin
    end

    def highline
      @highline ||= begin
        require 'highline'
        HighLine.new
      end
    end

    def msg(message)
      begin
        stdout.puts message
      rescue Errno::EPIPE => e
        raise e
        exit 0
      end
    end

    alias :info :msg

    def err(message)
      begin
        stderr.puts message
      rescue Errno::EPIPE => e
        raise e
        exit 0
      end
    end

    def warn(message)
      err("#{color('WARNING:', :yellow, :bold)} #{message}")
    end

    def error(message)
      err("#{color('ERROR:', :red, :bold)} #{message}")
    end

    def fatal(message)
      err("#{color('FATAL:', :red, :bold)} #{message}")
    end

    def color(string, *colors)
      if color?
        highline.color(string, *colors)
      else
        string
      end
    end

    def color?
      stdout.tty?
    end

    def self.instance
      @instance ||= Hazetug::UI.new(STDOUT, STDERR, STDIN)
    end

  end
end