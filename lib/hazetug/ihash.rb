require 'hashie'

class IHash < ::Hash
  include Hashie::Extensions::IndifferentAccess
end