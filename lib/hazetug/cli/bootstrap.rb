require 'agent'
require 'hazetug/cli/action'
require 'hazetug/tug'
require 'hazetug/task'

class Hazetug
  class CLI
    class Bootstrap < Action
      def execute
        concurrency = data[:opts][:concurrency].to_i || 1
        queue = channel!(Object, concurrency)
        waitgroup = Agent::WaitGroup.new
        bootstrap_list do |haze, tug|
          queue << nil; waitgroup.add(1)
          block = method(:provision_and_bootstrap).to_proc
          go!(haze, tug, queue, waitgroup, &block)
        end
        waitgroup.wait
      end

      def task
        yaml_task = data[:args].shift
        @task ||= Hazetug::Task.load_from_file(yaml_task)
      end

      def provision_and_bootstrap(haze, tug, channel, waitgroup)
        haze.provision
        if haze.ready?
          tug.load_haze_config(haze.config_for_tug)

          tug.bootstrap({
            args:  data[:args],
            opts:  data[:opts],
            gopts: data[:gopts]
          })
        end
      rescue
        # Exeception will be lost, since we run inside goproc,
        # ie. as soon as waitgroup is empty all process exit.
        puts $!.inspect
        puts $@
      ensure
        waitgroup.done
        channel.receive
      end

      def bootstrap_list(&block)
        return if block.nil?
        task.hosts_to_bootstrap(command_variables) do |conf|

          if convert_rand_name(conf[:name]) == conf[:name] && num > 1
            ui.fatal "Can't bootstrap several hosts with the same name"
            raise ArgumentError, "%rand(x)% expected"
          end

          num = conf[:number] || data[:opts][:number].to_i || 1
          (1..num).each do
            newconf = conf.dup
            newconf[:name] = convert_rand_name(conf[:name])

            haze = Hazetug::Haze[data[:compute_name]].new(newconf)
            
            if haze.config[:ssh_password]
              # Ensure a dynamic password loaded back from haze
              newconf[:ssh_password] = haze.config[:ssh_password]
            end

            tug  = Hazetug::Tug[data[:tug_name]].new(newconf)
            block.call(haze, tug)
          end
        end
      end

      def command_variables
        @command_variables ||= begin
          env = {}
          arr = data[:opts][:variables]
          if arr
            arr.each do |eq|
              k, v = eq.split('=')
              env[k] = v
            end
          end
          env
        end
      end

      def convert_rand_name(name)
        name.sub(/%rand\((\d+)\)%/) do |m|
          rand(36**$1.to_i).to_s(36)
        end
      end

    end
  end
end