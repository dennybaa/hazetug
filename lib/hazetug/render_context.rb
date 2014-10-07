require 'hazetug/taskfile'

class Hazetug
  class Taskfile

    class RenderContext
      render_context_dir = File.expand_path('..', __FILE__) + '/render_context'

      Dir.glob("#{render_context_dir}/*.rb").each do |path|
        name = File.basename(path, '.rb')

        require "hazetug/render_context/#{name}"
        include RenderContext.const_get(Hazetug.dash_capitalize(name))
      end

      def initialize(raw_data=nil)
        @raw_data = raw_data
      end

    end

  end
end
