require 'ostruct'
require 'optparse'

module Ziltoid
  class CommandParser

    ALLOWED_COMMANDS = ["watch", "start", "stop", "restart"]

    # Returns a structure describing the options.
    def self.parse(args)
      runnable = OpenStruct.new

      helptext = <<-HELP
        Available commands are :
           watch :       watches all processes
           start :       starts all processes
           stop  :       stops all processes
           restart :     restarts all processes
      HELP

      opt_parser = OptionParser.new do |opts|
        # Printing generic help at the top of commands summary
        opts.banner = "Usage: ziltoid.rb [options]"
        opts.separator ""
        opts.separator helptext
        opts.separator ""
        opts.separator "Common options :"

        # No argument, shows at tail. This will print a commands summary.
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      # Retrieves all arguments except option-like ones (e.g. '-h' or '-v')
      opt_parser.parse!(args)
      # Fetches the first argument as the intended command
      command = args.shift

      # Making sure the command is valid, otherwise print commands summary
      if command && ALLOWED_COMMANDS.include?(command)
        runnable.command = command
      else
        puts opt_parser.help
        exit
      end

      runnable
    end  # parse()

  end
end