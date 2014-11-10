require 'hashie/mash'
require 'forwardable'

class Hazetug
  class Haze
    module DSL
      extend Forwardable

      module ClassMethods

        # Haze options DSL methods
        def requires(*args); dsllist(:@requires, *args); end
        def compute_uses(*args); dsllist(:@compute_uses, *args); end
        def option_map(*args); dslmap(:@option_map, *args); end
        def nodespec_map(*args); dslmap(:@nodespec_map, *args); end
        def nodespec_string(*args); dslmap(:@nodespec_string, *args); end

        protected

        # Stores mappings
        def dslmap(variable, *args)
          hash = instance_variable_get(variable) || instance_variable_set(variable, Hashie::Mash.new)
          # read is invoked
          if args.empty?
            hash
          else
            key, mapping = args
            hash[key] = mapping
          end
        end

        # Stores list of values
        def dsllist(variable, *args)
          list = instance_variable_get(variable) || instance_variable_set(variable, [])
          if args.empty?
            list
          else
            args.inject(list) {|l, o| l << o if !l.include?(o); l}
          end
        end
      end

      def self.included(base)
        base.send :extend, ClassMethods
      end

      attr_reader :spec, :raw_node_spec, :compute_spec

      # Set provision spec, split input data into node and compute specific.
      # Input data looks like 
      # {
      #   "client_id"=>"digitalocean_client id ....",
      #   "api_key"=>"digitalocean_api key ....",
      #   "some_key"=>"my_value",
      #   "name"=>"api-ea8bfcfc",
      #   "node"=>{"location"=>"amsterdam", "flavor"=>"4gb", "image"=>"ubuntu 14.04"},
      # }
      def load_spec(spec)
        # check before we translate spec keys
        check_required! spec
        tspec = translate_spec spec
        # load order matters!
        load_node_spec! tspec
        load_compute_spec! tspec
        @spec = tspec
        build_node_spec
        true
      end

      protected

      # Translate specification according to option_map
      def translate_spec(spec)
        spec.inject(Hashie::Mash.new) do |mash, (k, v)|
          newkey = option_map[k]
          mash[newkey || k] = v
          mash
        end
      end

      # Build a compute spec used to create fog instance, for example
      # DigitalOcean uses the following arguments digitalocean_api_url, 
      # digitalocean_api_key, digitalocean_client_id.
      def load_compute_spec!(spec)
        @compute_spec = compute_uses.inject(Hashie::Mash.new) do |mash, arg|
          mash[arg] = spec.delete(arg) if spec[arg]
          mash
        end
      end

      # Build up provision spec which is used to describe create cloud server.
      # Namely name and node descripton such as location, flavor etc
      def load_node_spec!(spec)
        @raw_node_spec ||= begin
          mash = Hashie::Mash.new(spec.delete(:node))
          mash[:name] = spec.delete(:name)
          wrong = mash.keys.map(&:to_sym).select { |k| !nodespec_attrs.include?(k) }
          unless wrong.empty?
            ui.error "Wrong node specification, attributes not recognized: #{wrong.join(', ')}"
            exit 1
          end
          mash
        end
      end

      # Check required options, there are two sources of it: the taskfile or fog
      # configuration file. If required options are can't be retrieved from the
      # taskfile then fog configuration file must exist.
      def check_required!(spec)
        required = requires.select {|k| spec[k].nil?}
        unless required.empty? || has_fog_config?
          msg = required.map(&:to_s).join(', ')
          log.error %Q(Haze #{capital_name} requires options: #{msg})
          exit 1
        end
      end

      def build_node_spec
        raise NotImplementedError, '#build_node_spec must be implemented!'
      end

      def_delegators :'self.class', :option_map, :requires, :compute_uses,
                                    :nodespec_map, :nodespec_string


    end
  end
end
