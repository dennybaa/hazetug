require 'hazetug/config'
require 'hazetug/compute'
require 'hazetug/ui'
require 'hazetug/tug'
require 'chef/mash'

class Hazetug
  class Haze
    include Hazetug::UI::Mixin

    RE_BITS  = /-?x(32)$|-?x(64)$|(32)bit|(64)bit/i
    attr_reader :config, :compute, :compute_name, :server

    def initialize(config={})
      @compute_name = Hazetug.leaf_klass_name(self.class)
      @compute = Hazetug::Compute.const_get(compute_name).new
      @config  = configure(config)
      @server  = nil
      @sshable = false
    end

    def provision
      provision_server
      wait_for_ssh
    rescue Fog::Errors::Error
      ui.error "[#{compute_name}] #{$!.inspect}"
      ui.msg   $@
      exit(1)
    end

    def configure(config)
      input = config.keys.map(&:to_sym)
      requires = self.class.requires
      unless (norequired = requires.select {|r| not input.include?(r)}).empty?
        ui.error "Required options missing: #{norequired.join(', ')}"
        raise ArgumentError, "Haze options missing"
      end
      Mash.new(self.class.defaults.merge(config))
    end

    class << self
      def requires(*args)
        if args.empty?
          @requires
        else
          @requires = args.flatten.dup
        end
      end

      def defaults(hash=nil)
        if hash.nil?
          @defaults
        else
          @defaults = hash
        end
      end

      def [](haze_name)
        klass = Hazetug.camel_case_name(haze_name)
        Hazetug::Haze.const_get(klass)
      end
    end

    def public_ip_address
    end

    def private_ip_address
    end

    protected

    def provision_server
      ui.error "#{compute_name} Provisioning is not impemented"
    end

    def wait_for_ssh
      ui.error "#{compute_name} Waiting for shh is not impemented"
    end

  end
end