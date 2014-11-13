module Ziltoid
  class Process
    attr_accessor :name, :ram_limit, :cpu_limit, :start_command, :stop_command, :restart_command, :pid_file

    def initialize(name, options = {})
      self.name = name
      self.ram_limit = options[:limit] ? options[:limit][:ram] : nil
      self.cpu_limit = options[:limit] ? options[:limit][:cpu] : nil
      self.pid_file = options[:pid_file] || "~/.ziltoid/#{name}.pid"

      if options[:commands]
        self.start_command = options[:commands][:start] || nil
        self.stop_command = options[:commands][:stop] || nil
        self.restart_command = options[:commands][:restart] || nil
      end
    end

    def pid
      File.read(self.pid_file).to_i
    end

    def above_cpu_limit?(include_children = true)
      Ziltoid::System.cpu_usage(self.pid, include_children) > self.cpu_limit.to_i
    end

  end
end