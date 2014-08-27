require 'fog/core'
require 'fog/xml'
require 'fog/json'
require 'fog/core/parser'

class Hazetug
  class Compute
    autoload :Linode, 'fog/linode'
    autoload :DigitalOcean, 'fog/digitalocean'

    module CloudMixin
      CLOUD_MODELS = [
        :locations,
        :flavors,
        :images
      ]

      def cloud?
        true
      end

      def cloud_models
        Hazetug::Compute::CloudMixin::CLOUD_MODELS
      end

      CLOUD_MODELS.each do |method_name|
        define_method(method_name) do
          collection = self.class.const_get(:CollectionMap) || {}
          map_method = collection[method_name] ? collection[method_name] : method_name
          fog.send(map_method)
        end
      end
    end

    class Base
      def initialize(*args)
        klass = self.class.name.split('::').last
        @fog = Fog::Compute.const_get(klass).new(*args)
      end

      def method_missing(method_name, *args, &block)
        # cache all missing methods calls
        self.class.module_eval <<-EOS, __FILE__, __LINE__
          def #{method_name}(*args, &block)
            fog.#{method_name}(*args, &block)
          end
          EOS
        fog.send(method_name, *args, &block)
      end

      class << self
        def collection_map(mapping)
          @collection_map = mapping
          unless const_defined?(:CollectionMap)
            module_eval "CollectionMap = @collection_map"
          end
        end
      end

      private

      attr_reader :fog
    end

    class Linode < Base
      include CloudMixin
      collection_map({
        :locations => :data_centers
      })
    end

    class DigitalOcean < Base
      include CloudMixin
      collection_map({
        :locations => :regions
      })
    end

  end
end