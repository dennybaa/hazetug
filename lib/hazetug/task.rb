require 'psych'
require 'chef/mash'
require 'chef/mixin/deep_merge'
require 'hazetug/ui'

class Hazetug
  class Task
    include  Hazetug::UI::Mixin

    def initialize(path)
      path = File.expand_path(path)
      @task = Mash.new(Psych.load_file(path))
    rescue Psych::Exception
      ui.fatal "Unable to parse hazetug task file: '#{path}'"
      puts $!.inspect, $@
      exit(1)
    rescue SystemCallError
      ui.fatal "Unable to read file: '#{path}'"
      exit(1)
    end

    def [](key)
      @task[key]
    end

    def hosts_to_bootstrap(cmd_vars={}, &block)
      return if block.nil?
      base_conf = Mash.new(task)
      hosts = base_conf.delete(:bootstrap)
      base_conf = Chef::Mixin::DeepMerge.merge(base_conf, cmd_vars)
      hosts.each do |conf|
        merged = Chef::Mixin::DeepMerge.merge(base_conf, conf)
        block.call(merged)
      end
    end

    class << self
      protected :new

      def load_from_file(path)
        @instance ||= self.new(path)
      end

      def [](key)
        @instance and @instance[key]
      end
    end

    protected
    attr_reader :task

  end
end
