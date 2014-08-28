require 'gli'
require 'hazetug/cli/bootstrap'

class Hazetug
  class CLI
    include GLI::App

    def run(args)
      define_cli
      super
    end

    private

    def define_cli
      sort_help :manually
      switch [:v, :verbose]
      program_desc 'Provisions and bootstraps hosts in the cloud'

      {
        digital_ocean: 'DigitalOcean compute',
        linode:        'Linode Compute'
      }.each do |compute, compute_desc|
        desc compute_desc
        default_command :linode

        command compute.to_s.gsub(/_/,'') do |compute_cmd|

          compute_cmd.desc 'Provisions and bootstraps server'
          compute_cmd.command :bootstrap do |op|

            op.desc 'Bootstraps server using Knife'
            op.arg_name 'task.yaml'
            op.command :knife do |tug|
              tug.arg_name nil

              tug.flag [:v, :variables], :must_match => Array,
                :desc => 'Set variable or comma-seperated list of variables (var1_1=hello)'

              tug.flag [:n, :number], :default_value => 1,
                :desc => 'Set number of created nodes, value from yaml is honored'

              tug.flag [:c, :concurrency], :default_value => 1,
                :desc => 'Set concurrency value, i.e. number of hosts bootstraped simultaneously'

              tug.flag [:b, :bootstrap], :default_value => 'bootstrap.erb',
                :desc => 'Set path to knife bootstrap.erb file'

              tug.action do |gopts, opts, args|

                if args.empty?
                  commands[:help].execute({},{},tug.name_for_help)
                  exit 0
                end

                act = CLI::Action[:bootstrap].new
                act.pass(
                  tug_name: :knife,
                  compute_name: compute,
                  cli:   tug,
                  gopts: gopts,
                  opts:  opts,
                  args:  args
                ).execute
              end
            end

          end

        end
      end
    end

  end
end