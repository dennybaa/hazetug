require 'hazetug/tug/knife'
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

    attr_reader :haze, :config, :options

    def initialize(config={}, haze=nil)
      @haze = haze
      @config = config
    end

    def tug_name
      @tug_name ||= self.class.name.split('::').last
    end

    def bootstrap(options={})
      if haze && haze.server && haze.server.sshable?
        @options = options
        haztug_set_variables
        ip = config[:public_ip_address]
        ui.msg "[#{tug_name}] bootstraping server #{haze.config[:name]}, ip: #{ip}"
        exit_status = bootstrap_server
        if exit_status.is_a?(Fixnum) && exit_status != 0
          ui.error "[#{tug_name}] bootstraping server #{haze.config[:name]} failed."
        else
          ui.msg "[#{tug_name}] bootstraping server #{haze.config[:name]} done."
        end
      else
        ui.error "#{haze.compute_name} skipping bootstrap, server #{haze.config[:name]} not ready"
      end
    rescue Hazetug::Exception => e
      ui.error "[#{haze.compute_name}] #{e.message}"
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

    private

    def haztug_set_variables
      {
        compute_name: haze.compute_name.downcase,
        public_ip_address: (haze.public_ip_address || haze.server.ssh_ip_address rescue nil),
        private_ip_address: haze.private_ip_address
      }.each do |key, value|
        config[key] = value if value
      end
    end

    protected

    def create_log_file
      unless File.directory?(LOGDIR)
        Dir.mkdir(LOGDIR)
      end
      log = File.new("#{LOGDIR}/#{haze.config[:name]}", "w+")
      log.sync = true
      log
    end

  end
end