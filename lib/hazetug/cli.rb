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

            op.flag [:v, :variables], :must_match => Array,
              :desc => 'Set variable or comma-seperated list of variables (var1_1=hello)'

            op.flag [:n, :number], :default_value => 1,
              :desc => 'Set number of created nodes, value from yaml is honored'

            op.flag [:c, :concurrency], :default_value => 1,
              :desc => 'Set concurrency value, i.e. number of hosts bootstraped simultaneously'

            op.flag [:b, :bootstrap], :default_value => 'bootstrap.erb',
              :desc => "Set path to knife bootstrap.erb file"

            [:knife, :solo].each do |tug_cmd|
              mode = "#{tug_cmd == :knife ? 'client' : 'solo'}"


              op.desc "Bootstraps server using Knife in #{mode} mode"
              op.arg_name '<task.yaml>'
              op.command tug_cmd do |tug|
              
                tug.action do |gopts, opts, args|

                  if args.empty?
                    commands[:help].execute({},{},tug.name_for_help)
                    exit 0
                  end

                  act = CLI::Action[:bootstrap].new
                  act.pass(
                    tug_name: tug_cmd,
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
end
