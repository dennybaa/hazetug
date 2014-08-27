require 'psych'

class Hazetug
  class Config
    PATH = File.expand_path("~/.hazetug")

    class << self
      def load
        Fog.credentials_path = PATH
        @credentials ||= begin
          if File.exist?(PATH)
            Psych.load_file(PATH)[Fog.credential.to_s]
          else
            {}
          end
        end
      end

      def [](key)
        @credentials[key]
      end
    end

  end
end
Hazetug::Config.load