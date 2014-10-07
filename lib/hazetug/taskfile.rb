require 'tilt'
require 'tilt/erubis'
require 'tempfile'
require 'psych'
require 'hazetug/ihash'
require 'hazetug/render_context'

class Hazetug
  class Taskfile
    ALWAYS_RENDER = [:provision]

    # Define section access methods
    [:variables, :nodes, :hazes, :provision].each do |meth|
      define_method(meth) { render_task meth }
    end

    def initialize(path)
      @path = path
      @context = Taskfile::RenderContext.new IHash[Psych.load(raw_data)]
    end

    def cleanup
      tempfile.close
    end

    private

    attr_reader :context

    # Renders the taskfile and returns parsed YAML data
    def render_task(section=nil)
      section = section || :_none
      render  = ->{ IHash[Psych.load(template.render(context.dup))] }

      if ALWAYS_RENDER.include?(section)
        data = render.()
      else
        @rendered_data ||= render.()
        data = @rendered_data
      end
      section == :_none ? data : data[section]
    # to be rescued
    end

    def raw_data
      IO.read(@path)
    # to be rescued
    end


    # Tilt erubis template
    def template
      @template ||= Tilt::ErubisTemplate.new(tempfile.path)
    # to be rescued
    end

    # The actual task file is converted from the origin
    # by substituting <%= %> instead of {{ }}
    def tempfile
      @tempfile ||= begin
        f = Tempfile.new('hazetug-task')
        text = curlies_to_erb(raw_data)
        f.write(text)
        f.flush
        f
      end
    end

    def curlies_to_erb(text)
      text.gsub("{{", "<%=").gsub("}}", "%>")
    end

  end
end
