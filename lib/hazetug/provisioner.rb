require 'hazetug/taskfile'
require 'hazetug/haze'
require 'hazetug/tug'
require 'hazetug/logger'

class Hazetug
  class Provisioner

    class ProvisionPipe
      def initialize(&block)
        @pipe = []
        block.call(self) if block
      end

      def <<(o); @pipe << o; end
      def run; @pipe.each {|o| o.run}; end
      def undo; @pipe.each {|o| o.undo}; end
      def cleanup; @pipe.each {|o| o.cleanup}; end
      def success?; @pipe.all? {|o| o.success?}; end
    end

    class ProvisionCmd
      include Hazetug::Logger

      def initialize(arg=nil, &block)
        @status = false
        if block
          @run = block
        elsif arg
          @run = arg[:run] and @undo = arg[:undo]
        else
          log.error "Argument or block is required for ProvisionCmd.new"
          raise ArgumentError, "Hash or block is required"
        end

        unless @run.is_a? Proc
          log.error "ProvisionCmd.new run action must be Proc, #{@run.class} is given"
          raise ArgumentError, "Block is expected"
        end
      end

      def run
        @run.call
        @status = true
      end

      def undo; @undo.call if @undo; end
      def cleanup; undo unless success?; end
      def success?; @status; end
    end

    def initialize(path)
      path = 'examples/task1.yaml'
      #
      @taskfile = Taskfile.new(path)
    end

    def provision
      process = ProvisionPipe.new     

      # Create command hazetug execution pipeline, this parses the configuration
      # and after that executes the pipeline.
      nodes.each do |node|
        conf = haze_task(node.compute)
        haze = Haze.compute node.compute

        # Set merged haze compute configuration with the node specific
        haze.load_spec conf.merge(node.provision_conf)

        process << ProvisionPipe.new do |pipe|
          # Add haze provision command
          pipe << ProvisionCmd.new({
            run:  proc { haze.perform_with_message :provision, 'provisioning', 'provisioned' },
            undo: proc { haze.perform_with_message :destroy, 'destroying', 'destroyed'}
          })

          # Add tugs bootstrapping commands
          load_tugs(node.bootstrap_conf).each do |tug|
            pipe << ProvisionCmd.new { tug.bootstrap }
          end
        end
      end

      # process the pipeline
      process.run
      process.cleanup
    end

    private

    def provision_tasks; @taskfile.provision; end
    def haze_task(name); @taskfile.hazes[name]; end

    def load_tugs(tug_tasks)
      tug_tasks.map do |task|
        name, conf = task.first
        Tug.bootstrap(name.to_sym).new(conf)
      end
    end

    # Get list of nodes along with their configuration
    def nodes
      result = []
      provision_tasks.each_index do |pi|
        compute, nodes_arr = provision_tasks[pi].first
        compute = compute.to_sym

        nodes_arr.each_index do |ni|
          node_data = nodes_arr[ni]
          spawn = node_data[:number] || 1

          # Since multiple nodes might be created read the config is read several times,
          # this re-evaluates dynamic substitutions (ex. rand.* methods)
          (1..spawn).each {
            data = provision_tasks[pi][compute][ni]
            data.delete(:number)

            tug  = data.delete(:tug)
            result << OpenStruct.new(compute: compute, provision_conf: data, bootstrap_conf: tug)
          }
        end
      end
      result
    end

  end
end
