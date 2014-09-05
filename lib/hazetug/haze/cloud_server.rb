class Hazetug
  class Haze
    module CloudServer

      def provision_server
        ui.info "[#{compute_name}] creating server #{config[:name]}"
        self.server = compute.servers.create(server_args)
        server.wait_for { ready? }
        ui.info "[#{compute_name}] server #{config[:name]} created, ip: #{server.ssh_ip_address}"
      end

      def wait_for_ssh
        server.username = config[:ssh_user] || 'root'
        server.ssh_port = config[:ssh_port]
        server.ssh_options = net_ssh_options

        ui.info "[#{compute_name}] waiting for active ssh on #{server.ssh_ip_address}"
        server.wait_for(30) { sshable? }
        @ready = true
      rescue Fog::Errors::TimeoutError
        ui.error "[#{compute_name}] ssh failed to #{config[:name]}, ip: #{server.ssh_ip_address}"
      end

      def lookup(model, *args)
        collection_method = model.to_s + 's'
        compare_method = "compare_#{model}?"
        found = compute.send(collection_method).select do |o|
          self.send(compare_method, o, *args)
        end
        if found.size > 1
          ui.error "More than one #{model} found for #{config[model]}"
        elsif found.empty?
          ui.fatal "#{model} not found for #{config[model]}"
          raise ArgumentError, "Wrong argument #{config[model]}"
        end
        found.first
      end

      def memory_in_megabytes(string)
        mult = 1
        mult = 1024 if string.match(/gb$/i)
        string.to_i * mult
      end

      def image_from_string(string)
        string.downcase.sub(/\s*lts\s*/, '').
          sub(RE_BITS, '').
          sub(/\s+$/, '').
          gsub(/ /, '-')
      end

      # Bits from string, when can't be fetched default is 64
      def bits_from_string(string)
        m = string.match(Haze::RE_BITS)
        m ? m.captures.compact.first.to_s.to_i : 64
      end

      def server_args
        @server_args ||= create_server_args
      end

      def create_server_args
        raise NotImplementedError, "#create_server_arguments not implemented"
      end

    end
  end
end