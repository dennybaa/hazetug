require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'berkshelf'
require 'berkshelf/berksfile'
require 'json'
require 'hazetug/tug/knife_base'

class Hazetug
  class Tug
    class Solo < KnifeBase

      def initialize(config={})
        super
        @upload_dest = '/tmp/hazetug-cookbooks.tar.gz'
      end

      def bootstrap_config
        super
        config[:attributes_json] = json_attributes
        config[:cookbooks_file] = @upload_dest

        check_bootstrap_files! :template_file, :berksfile
      end

      def bootstrap_init
        upload_berks_package
      end

      def bootstrap_cleanup
        ssh = Fog::SSH.new(config[:public_ip_address], ssh_username, ssh_options)
        ssh.run("test -f #{@upload_dest} && rm #{@upload_dest}")
      end

      def berks_package(&block)
        berks = Berkshelf::Berksfile.from_file(bootstrap_options[:berksfile])

        Dir::Tmpname.create('hazetug-cookbooks') do |path|
          begin
            berks.package(path)
            block.call(path)
          ensure
            File.unlink(path) if File.exist?(path)
          end
        end
      end

      def upload_berks_package
        berks_package do |path|
          scp = Fog::SCP.new(config[:public_ip_address], ssh_username, ssh_options)
          scp.upload(path, @upload_dest)
        end
      end

      def bootstrap_options
        @bootstrap_options ||= begin
          opts = super
          opts[:berksfile] = config[:berksfile] || 'Berksfile'
          opts
        end
      end

      def json_attributes
        @json_attributes ||= begin
          hash = config[:attributes] || {}
          hash[:run_list] = config[:run_list] || []
          JSON.pretty_generate(hash)
        end
      end

      private

      def ssh_options
        @ssh_options ||= begin
          ssh_options = {}
          ssh_opts = Hazetug::Tug.ssh_options_from(config)
          ssh_options[:password] = ssh_opts[:ssh_password]
          ssh_options[:paranoid] = ssh_opts[:host_key_verify] || false
          ssh_options[:keys] = ssh_opts[:ssh_keys] || Hazetug.ssh_keys(config[:compute_name])
          ssh_options[:port] = ssh_opts[:ssh_port]
          ssh_options
        end
      end

      def ssh_username
        config[:ssh_user] || 'root'
      end

    end
  end
end
