require 'hazetug/version'
require 'hazetug/compute'
require 'hazetug/haze'
require 'hazetug/haze/linode'
require 'hazetug/haze/digital_ocean'

class Hazetug
  class Exception < ::Exception
  end

  class << self
    def camel_case_name(string_or_symbol)
      string_or_symbol.to_s.split('_').map(&:capitalize).join
    end

    def leaf_klass_name(klass)
      if klass.is_a? String
        klass.split('::').last
      else
        klass.name.split('::').last
      end
    end

    def ssh_keys(compute_name=nil)
      ssh_attr = []
      ssh_attr << "#{compute_name.downcase}_ssh_keys" if compute_name
      ssh_attr << "ssh_keys"
      Hazetug::Config[ssh_attr.find {|a| Hazetug::Config[a]}]
    end
  end
end