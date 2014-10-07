require 'json'

class Hazetug
  class Taskfile
    class RenderContext

      module Section

        def node(name)
          section(:nodes)[name].to_json
        end

        def user(name)
          section(:variables)[name].to_json
        end

        def env(name)
          ENV[name]
        end

        private

        def section(section_name)
          (@raw_data || {})[section_name] || {}
        end
      end

    end
  end
end
