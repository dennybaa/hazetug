require 'tilt'
require 'tilt/erubis'
require 'tempfile'
require 'psych'
require 'hashie/mash'
require 'hazetug/render_context'
require 'hazetug/logger'

class Hazetug
  class Taskfile
    include Logger

    ALWAYS_RENDER = [:provision]

    # Define section access methods
    [:variables, :nodes, :hazes, :provision].each do |meth|
      define_method(meth) { render_task meth }
    end

    def initialize(path)
      @path = path
      @context = Taskfile::RenderContext.new Hashie::Mash[psych_load(raw_data)]
    end

    def cleanup
      tempfile.close
    end

    private

    attr_reader :context

    def psych_load(data)
      Psych.load(data)
    rescue Exception => ex
      log.error "Can not parse file `#{@path}': " + ex.message
      exit 1
    end

    # Renders the taskfile and returns parsed YAML data
    def render_task(section=nil)
      section = section || :_none
      render  = ->{ Hashie::Mash[psych_load(template.render(context.dup))] }

      if ALWAYS_RENDER.include?(section)
        data = render.()
      else
        @rendered_data ||= render.()
        data = Hashie::Mash[@rendered_data] # always return a copy of the data hash
      end
      section == :_none ? data : data[section]
    rescue Exception => ex
      log.error "Can not parse file `#{@path}': " + ex.message
      exit 1
    end

    def raw_data
      IO.read(@path)
    rescue Psych::Exception => ex
      log.error "Can not parse file `#{@path}': " + ex.message
      exit 1
    end

    # Tilt erubis template
    def template
      @template ||= Tilt::ErubisTemplate.new(tempfile.path)
    rescue Exception => ex
      log.error "Can not parse file `#{@path}': " + ex.message
      exit 1
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
