
require 'hazetug/ui'

class Hazetug
  class Haze

    class DigitalOcean < Haze
      compute_name :digitalocean
      requires :api_key, :client_id

      # Fog compute uses the following options, they will be passed to it.
      compute_uses :digitalocean_api_url, :digitalocean_api_key, :digitalocean_client_id

      # Used by compute
      option_map :api_url,   :digitalocean_api_url
      option_map :api_key,   :digitalocean_api_key
      option_map :client_id, :digitalocean_client_id

      # Used by provision
      option_map :backups, :backups_active
      option_map :private_network, :private_networking

      nodespec_map :location, :region
      nodespec_string :image, ->(o) { "#{o.distribution} #{o.name}" }

      def provision

      end

      # Compile DSL methods
      compile!
    end

  end
end
