require 'forwardable'
require 'fog/core'

# Previously treated as "core"
# data exchange specific (to be extracted and used on a per provider basis)
require 'fog/xml'
require 'fog/json'
require 'fog/core/parser'

# deprecation wrappers (XML wrapped version)
require 'fog/core/deprecated/connection'
require 'fog/core/deprecated_connection_accessors'

require 'hashie/mash'
require 'hazetug/logger'
require 'hazetug/ui'
require 'hazetug/haze/dsl'

class Hazetug
  class Haze
    extend Forwardable
    include Hazetug::Logger
    include Hazetug::Haze::DSL

    def_delegators :'self.class', :nodespec_attrs, :compute_name, :compute_cache
    def_delegator  :'self.class', :setup_fog_config, :has_fog_config?

    attr_reader :node_spec

    class << self
      include Logger

      def computes; @@computes ||= {}; end
      def compute_cache; @@compute_cache ||= {}; end

      # Retrieve class of a specific compute
      def compute(name)
        require "hazetug/haze/#{name}"
        require "fog/#{name}"
        setup_fog_config
        computes[name].new
      rescue LoadError
        log.error "Unable to load haze compute `#{name}'"
        raise
      end

      # Store symbol to class mapping
      def compute_name(name=nil)
        if name
          @compute_name    = name
          computes[name] ||= self
        else
          @compute_name
        end
      end

      # Node specification attributes (these are defaults), but might be extended
      # in a specific compute.
      def nodespec_attrs
        @nodespec_attrs ||= [:name, :location, :flavor, :image]
      end

      # Setup fog configuration if the file exists
      def setup_fog_config
        @@has_fog_config ||= begin
          # implement choosing
          path = File.join(ENV['HOME'], '.fog')
          unless File.exist? path
            false
          else
            Fog.credentials_path = path
            true
          end
        end
      end

      # Dynamically create methods and do setup using DSL provided information
      def compile!
        nodespec_attrs.each do |meth|
          # Create fog collection method invocation
          define_method("#{meth}s") { fog.send("#{nodespec_map[meth] || meth}s") }

          # Default node spec string returns object name (!?)
          if nodespec_string[meth].nil?
            nodespec_string[meth] = ->(o) { o.name }
          end
        end
      end
    end

    def capital_name; @capital_name ||= Hazetug.leaf_klass_name(self.class); end

    def provision
      raise NotImplementedError, "#provision method must be implemented"
    end

    def destroy
      raise NotImplementedError, "#destroy method must be implemented"
    end

    def perform_with_message(method_symbol, doing_msg, finished_msg=nil)
      finished_msg ||= doing_msg
      cl_name = ui.colored :node_name, raw_node_spec[:name]
      cl_compute = ui.colored :compute_name, capital_name

      ui.say "#{doing_msg.capitalize} node #{cl_name} in #{cl_compute}."
      self.send(method_symbol)
      ui.say ui.colored(:success, "Successfully #{finished_msg.downcase}") + " node #{cl_name}."
    rescue
      ui.say ui.colored(:error, "Failed #{doing_msg}") + " node #{cl_name}."
    end

    # Setup ui and its colors
    def ui
      @ui ||= begin
        _ui = Ui::Color.new
        _ui.color_cache.merge!({
          node_name: [:bold, :blue],
          node_attr_value: [:green],
          compute_name: [:bold, :blue],
          success: [:bold, :green]
        })
        _ui
      end
    end

    # Lookup fog cloud for attribute matching id or regex
    def lookup(attribute, arg)
      case arg
      when Fixnum # use ID
        send("#{attribute}s").find {|o| o.identity == arg}
      when String # use regex
        send("#{attribute}s").select do |o|
          nodespec_string[attribute].(o) =~ /^#{arg}/i
        end
      end
    end

    # List attributes from a list
    def nodespec_list(attribute, list)
      maxlen = list.map { |o| nodespec_string[attribute].(o) }.max.size
      list.map do |o|
        "%-*s,\tid: %d" %  [ maxlen, nodespec_string[attribute].(o), o.identity ]
      end
    end

    protected

    # Build up fog nodespec which is parsed and looked up in a cloud compute
    # openstruct with all its attributes set for location, flavor and etc.
    def build_node_spec
      @node_spec ||= begin
        cl_name = ui.colored :node_name, raw_node_spec[:name]
        cl_compute = ui.colored :compute_name, capital_name

        ui.say "Preparing for node #{cl_name} creation in #{cl_compute}..."

        inhash = {name: raw_node_spec[:name]}
        built = (nodespec_attrs - [:name]).inject(inhash) do |hash, spec_attr|

          found = lookup(spec_attr, raw_node_spec[spec_attr])
          cl_value = ui.colored :node_attr_value, raw_node_spec[spec_attr]

          if found.empty?
            ui.error "Couldn't find #{spec_attr} in #{cl_compute} for `#{cl_value}'"
            exit 1
          elsif found.size >= 2
            ui.say "Multiple #{spec_attr}s found in #{cl_compute} for `#{cl_value}'"
            ui.say "Choose one of the following #{spec_attr}s:"

            choices = nodespec_list(spec_attr, found)
            (1..found.size).each do |i|
              ui.say "%2d) %s" % [ i, choices[i-1] ]
            end
            num = ui.ask('Select number: ', ->(ans){ans.to_i}) do |q|
              q.in = (1..found.size)
            end

            hash[spec_attr] = found[num-1]
          else
            hash[spec_attr] = found.first
          end
          hash
        end
        OpenStruct.new(built)
      end
    end

    # Fog compute instance (cached)
    def fog
      id = { compute: compute_name, data: compute_spec }
      compute_cache[id] or begin
        api = case requires.empty?
          when true
            # rely on compute options that might be given in ~/.fog config
            Fog::Compute[compute_name]
          else
            Fog::Compute.const_get(capital_name).new(compute_spec)
          end
        compute_cache[id] = fog_setup(api)
      end
    end

    # Fog configuration handler, default passes fog instance as is.
    def fog_setup(fog); fog; end

  end
end
