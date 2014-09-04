require 'erubis'
require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'chef/knife/core/bootstrap_context'
require 'hazetug/tug'

# Extend knife bootstrap context with our data.
# It's monkey patching, yey :)
class Chef::Knife::Bootstrap
  def render_template(template=nil)
    context = Chef::Knife::Core::BootstrapContext.new(config, config[:run_list], Chef::Config)
    @extended_bootstrap_variables.each do |s, v|
      context.instance_variable_set(s, v)
    end
    Erubis::Eruby.new(template).evaluate(context)
  end

  def add_variable_to_bootstrap_context(variable_sym, value)
    @extended_bootstrap_variables ||= {}
    @extended_bootstrap_variables[variable_sym] = value if value
  end
end

class Chef::Knife::Core::BootstrapContext
  def hazetug; @hazetug; end
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
    class KnifeBase < Tug

      def initialize(config={})
        super
        @bootstrap_option_list = [
          :template_file,
          :identity_file,
          :ssh_user,
          :ssh_password,
          :host_key_verify
        ]
      end

      # Bootstraps the remote server using knife bootstrap.
      def bootstrap_server
        bootstrap_config

        bootstrap_init
        bootstrap_run
        bootstrap_cleanup
      rescue Hazetug::Exception => e
        ui.error(e.message); 1
      ensure  
        knife and knife.ui.stdout.close
      end

      # Configures knife bootstrap by setting the necessary options.
      def bootstrap_config
        knife.add_variable_to_bootstrap_context(:@hazetug, config)

        @bootstrap_option_list.each do |opt|
          knife.config[opt] = bootstrap_options[opt]
        end

        # Check ssh identity
        cred = [
          hazetug_identity, bootstrap_options[:identity_file],
          bootstrap_options[:ssh_password]
        ]

        if cred.all?(&:nil?)
          msg = "No identity (inc. ssh_password) found. Check ssh_password," <<
            " identity_file options or #{config[:compute_name]}_ssh_keys " <<
            "hazetug parameter."

          raise Hazetug::Exception, msg
        end
      end

      # Pre knife bootstrap hook.
      def bootstrap_init
      end

      # After knife bootstrap hook.
      def bootstrap_cleanup
      end

      # Initiates knife bootstrap run.
      def bootstrap_run
        knife.name_args = [config[:public_ip_address]]
        knife.run
      end

      # Initializes knife bootstrap, default output is redirected into file.
      def knife
        @knife ||= begin
          lf = create_log_file
          Chef::Knife::Bootstrap.load_deps
          kb = Chef::Knife::Bootstrap.new
          kb.ui = Chef::Knife::UI.new(lf, lf, lf, {verbosity: 2})
          kb
        end
      end

      # Extracts bootstrap options from the hazetug configuration.
      def bootstrap_options
        @bootstrap_options ||= begin
          opts = {}

          opts[:ssh_user] = config[:ssh_user] || 'root'
          opts[:ssh_password] = config[:ssh_password]
          if opts[:ssh_password].nil?
            opts[:identity_file] = config[:identity_file] || hazetug_identity
          end

          template = options[:opts][:bootstrap] || 'bootstrap.erb'
          validation = config[:chef_validation_key] || 'validation.pem'

          opts[:validation_key] = File.expand_path(validation)
          opts[:template_file]  = File.expand_path(template)
          opts[:environment]  =  config[:chef_environment]
          opts[:host_key_verify] = config[:host_key_verify] || false
          opts[:chef_server_url] = config[:chef_server_url]
          opts
        end
      end

      # Lookup ssh identity key(s) in the hazetug configuration.
      def hazetug_identity
        @hazetug_identity ||= begin
          compute = config[:compute_name]
          key_path = (Hazetug::Config["#{compute}_ssh_keys"] || []).first
          key_path and File.expand_path(key_path)       
        end
      end

      # Check if files exist otherwise fail.
      def check_bootstrap_files!(*list_of_opts)
        list = list_of_opts.map {|k| bootstrap_options[k]}
        files = list.map {|f| File.expand_path(f.to_s)}
        notfound = files.select {|f| !File.exist?(f)}
        notfound.empty? or 
          raise Hazetug::Exception, "File(s) not found: #{notfound.join(', ')}"
      end

    end
  end
end
