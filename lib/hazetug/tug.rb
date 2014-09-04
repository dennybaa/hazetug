require 'hazetug/tug/knife'
require 'hazetug/tug/solo'
require 'hazetug/ui'
require 'chef/mash'

class Hazetug
  class Tug
    include Hazetug::UI::Mixin

    SSH_OPTIONS = [
      :ssh_user, :ssh_password, :ssh_port,
      :ssh_host_key_verify, :ssh_keys
    ]
    LOGDIR = "#{Dir.pwd}/logs"

    attr_reader :config, :options

    def initialize(config={})
      @config = config
    end

    def tug_name
      @tug_name ||= self.class.name.split('::').last
    end

    def bootstrap(options={})
      @options = options
      ip = config[:public_ip_address]

      ui.msg "[#{tug_name}] bootstraping server #{config[:name]}, ip: #{ip}"
      exit_status = bootstrap_server

      if exit_status.is_a?(Fixnum) && exit_status != 0
        ui.error "[#{tug_name}] bootstraping server #{config[:name]} failed."
      else
        ui.msg "[#{tug_name}] bootstraping server #{config[:name]} done."
      end
    rescue Hazetug::Exception => e
      ui.error "[#{config[:compute_name]}] #{e.message}"
    end

    def load_haze_config(hash)
      @config.merge!(hash)
    end

    class << self
      def [](symbol_or_string)
        klass = Hazetug.camel_case_name(symbol_or_string)
        const_get(klass)
      end

      def ssh_options_from(config)
        SSH_OPTIONS.inject({}) do |hash, k|
          if value = (config[k])
            hash[k] = value
          end
          hash
        end
      end
    end

    protected

    def create_log_file
      unless File.directory?(LOGDIR)
        Dir.mkdir(LOGDIR)
      end
      log = File.new("#{LOGDIR}/#{config[:name]}", "w+")
      log.sync = true
      log
    end

  end
end