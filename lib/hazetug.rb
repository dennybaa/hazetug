require 'hazetug/hazetug'
require 'hazetug/cli'

Hazetug::CLI.new.run(ARGV) if $0 == __FILE__
