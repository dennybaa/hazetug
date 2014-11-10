
class Hazetug
  class << self
    def dash_capitalize(string)
      string.split('_').map {|w| w.capitalize}.join
    end

    def leaf_klass_name(klass)
      klass.to_s.split('::').last
    end
  end
end
