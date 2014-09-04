require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'hazetug/tug/knife_base'

class Hazetug
  class Tug
    class Knife < KnifeBase

      def initialize(config={}, haze=nil)
        super
        @chef_option_list = [
          :environment,
          :chef_server_url,
          :validation_key
        ]
      end

      def bootstrap_config
        super
        @chef_option_list.each do |opt|
          Chef::Config[opt] = bootstrap_options[opt]
        end
        check_bootstrap_files! :validation_key, :template_file
      end

    end
  end
end
