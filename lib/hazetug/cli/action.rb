require 'hazetug/ui'

class Hazetug
  class CLI
    class Action
      attr_reader :data

      def ui
        Hazetug::UI.instance
      end

      def pass(hash={})
        @data = hash.dup
        self
      end

      class << self
        def inherited(child)
          action = child.name.split('::').last.downcase.to_sym
          @actions ||= {}
          @actions[action] = child
        end

        def [](value)
          @actions[value]
        end
      end
    end
  end
end