class Hazetug
  module NetSSH

    module Mixin
      NET_SSH_OPTIONS = [
        :ssh_password, :ssh_port, :ssh_host_key_verify, :ssh_keys ]

      private

      def net_ssh_options
        @net_ssh_options ||= begin
          hash = {}
          ssh_opts = pick_ssh_options
          hash[:password] = ssh_opts[:ssh_password]
          hash[:paranoid] = ssh_opts[:host_key_verify] || false
          hash[:keys] = ssh_opts[:ssh_keys] || NetSSH.ssh_keys(config[:compute_name])
          hash[:port] = ssh_opts[:ssh_port]
          hash
        end
      end

      def pick_ssh_options
        NET_SSH_OPTIONS.inject({}) do |hash, k|
          if value = (config[k])
            hash[k] = value
          end
          hash
        end
      end
    end

    def self.ssh_keys(compute_name=nil)
      ssh_attr = []
      ssh_attr << "#{compute_name.downcase}_ssh_keys" if compute_name
      ssh_attr << "ssh_keys"
      Hazetug::Config[ssh_attr.find {|a| Hazetug::Config[a]}]
    end

  end
end