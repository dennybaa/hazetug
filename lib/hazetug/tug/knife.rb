require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'hazetug/tug/knife_base'

class Hazetug
  class Tug
    class Knife < KnifeBase

      def initialize(config={})
        super
        [ :chef_server_url,
          :validation_key
        ].inject(@chef_option_list, :<<)
      end

      def bootstrap_config
        super
        check_bootstrap_files! :validation_key, :template_file
      end

    end
  end
end
