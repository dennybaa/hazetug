require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'hazetug/tug'

# Monkey Patch:)
# Extend knife bootstrap context with our data
class Chef::Knife::Core::BootstrapContext
  def hazetug; @config[:hazetug]; end
end

class Chef::Knife::Ssh < Chef::Knife
  def run
    extend Chef::Mixin::Command
    @longest = 0
    configure_attribute
    configure_user
    configure_password
    configure_identity_file
    configure_gateway
    configure_session
    exit_status = ssh_command(@name_args[1..-1].join(" "))
    session.close

    exit_status
  end
end

class Hazetug
  class Tug
    class Knife < Tug

      def bootstrap_server
        [
          :template_file,
          :identity_file,
          :ssh_user,
          :ssh_password,
          :host_key_verify
        ].each do |opt|
          kb.config[opt] = bootstrap_options[opt]
        end
        [
          :environment,
          :chef_server_url,
          :validation_key
        ].each do |opt|
          Chef::Config[opt] = bootstrap_options[opt]
        end
        kb.name_args = [haze.server.ssh_ip_address]
        kb.run
      rescue Hazetug::Exception => e
        ui.error(e.message); 1
      ensure  
        @kb and @kb.ui.stdout.close
      end

      def kb
        @kb ||= begin
          lf = create_log_file
          Chef::Knife::Bootstrap.load_deps
          kb = Chef::Knife::Bootstrap.new
          kb.config[:hazetug] = config
          kb.ui = Chef::Knife::UI.new(lf, lf, lf, {verbosity: 2})
          kb
        end
      end

      def bootstrap_options
        @bootstrap_options ||= begin
          template = options[:opts][:bootstrap] || 'bootstrap.erb'
          validation = config[:chef_validation_key] || 'validation.pem'

          files = [template, validation].map {|f| File.expand_path(f)}
          notfound = files.select {|f| !File.exist?(f)}
          notfound.empty? or 
            raise Hazetug::Exception, "File(s) not found: #{notfound.join(', ')}"

          opts = {}
          opts[:validation_key] = File.expand_path(validation)
          opts[:template_file]  = File.expand_path(template)
          opts[:ssh_user] = config[:ssh_user] || 'root'
          opts[:ssh_password] = config[:ssh_password]
          opts[:environment]  =  config[:chef_environment]
          opts[:host_key_verify] = config[:host_key_verify] || false
          opts[:chef_server_url] = config[:chef_server_url]
          opts[:identity_file]   = preferred_ssh_identity if not opts[:ssh_password]
          opts
        end
      end

      def preferred_ssh_identity
        @preferred_ssh_identity ||= begin
          compute = Hazetug.leaf_klass_name(haze.class.name).downcase
          identity = config[:identity_file]
          key_path = (Hazetug::Config["#{compute}_ssh_keys"] || []).first
          if identity.nil? && key_path.nil?
            raise Hazetug::Exception, "identity file not specified, use #{compute}_ssh_keys or identity_file"
          end
          identity ||= File.expand_path(key_path)
          identity
        end
      end

    end
  end
end
