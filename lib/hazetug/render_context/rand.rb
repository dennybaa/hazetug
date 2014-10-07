require 'securerandom'
require 'forwardable'

class Hazetug
  class Taskfile
    class RenderContext

      module RandContext
        extend Forwardable

        def_delegators :SecureRandom, :uuid, :hex, :base64, :urlsafe_base64
        def_delegator  :SecureRandom, :random_number, :number
      end

      module Rand
        def rand
          @irand_context ||= Object.new.extend(RandContext)
        end
      end

    end
  end
end
