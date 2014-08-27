require 'securerandom'
require 'hazetug/haze/cloud_server'

class Hazetug
  class Haze
    class Linode < Haze
      include CloudServer

      requires :name, :location, :flavor, :image
      defaults :payment_terms => 1

      def initialize(config={})
        super
        @config[:bits] = bits_from_string(@config[:image])
        @config[:image_slug] = image_from_string(@config[:image])
        @config[:ssh_password] ||= SecureRandom.hex
      end

      def create_server_args
        latest = /^Latest #{config[:bits]} bit/
        {
          :name => config[:name],
          :data_center => lookup(:location),
          :flavor => lookup(:flavor),
          :image  => lookup(:image),
          :kernel => compute.kernels.find {|k| k.name.match(latest)},
          :password => config[:ssh_password],
          :payment_terms => config[:payment_terms]
        }
      end

      def compare_location?(o)
        a = o.attributes
        value = config[:location]
        a[:location].match(/^#{value}/i) != nil ||
        a[:abbr] == config[:location] || a[:abbr].match(/^#{value}/) != nil
      end

      def compare_flavor?(o)
        a = o.attributes
        value = config[:flavor]
        a[:ram] == memory_in_megabytes(value) ||
        a[:name].match(/^#{value}/i)
      end

      def compare_image?(o)
        a = o.attributes
        img_id = image_from_string(a[:name])
        bits = a[:bits]
        img_id.match(/^#{config[:image_slug]}/) && bits == config[:bits]
      end

      def public_ip_address
        server and server.public_ip_address
      end

      def private_ip_address
        server and begin
          found = server.ips.find {|ip| not ip.public}
          found and found.ip
        end
      end

    end
  end
end