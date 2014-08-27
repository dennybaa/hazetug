require 'hazetug/haze/cloud_server'

class Hazetug
  class Haze
    class DigitalOcean < Haze
      include CloudServer

      requires :name, :location, :flavor, :image
      defaults :backups_active => true, :private_networking => true

      def initialize(config={})
        super
        @config[:bits] = bits_from_string(@config[:image])
        @config[:image_slug] = image_from_string(@config[:image])
      end

      def create_server_args
        {
          :name => config[:name],
          :region_id => lookup(:location).id,
          :flavor_id => lookup(:flavor).id,
          :image_id  => lookup(:image).id,
          :ssh_key_ids => ssh_key_ids,
          :backups_active => config[:backups_active],
          :private_networking => config[:private_networking]
        }
      end

      def compare_location?(o)
        a = o.attributes
        value = config[:location]
        a[:name].match(/^#{value}/i) != nil ||
        a['slug'] == config[:location] || a['slug'].match(/^#{value}/) != nil
      end

      def compare_flavor?(o)
        a = o.attributes
        value = config[:flavor]
        a[:memory] == memory_in_megabytes(value) ||
        a[:name].match(/^#{value}/i)
      end

      def compare_image?(o)
        a = o.attributes
        img_id = image_from_string(a[:name])
        bits = bits_from_string(a[:name])
        img_id.match(/^#{config[:image_slug]}/) && bits == config[:bits]
      end

      def public_ip_address
        server and server.public_ip_address
      end

      def private_ip_address
        server and server.private_ip_address
      end

      private

      def ssh_key_ids
        if config[:ssh_keys].nil? || config[:ssh_keys].empty?
          compute.ssh_keys.map(&:id)
        else
          config[:ssh_keys].map do |n|
            k = lookup(:ssh_key, n) and k.id
          end.compact
        end
      end
    end
  end
end