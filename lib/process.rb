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
      if self.pid_file && File.exist?(self.pid_file)
        str = File.read(pid_file)
        str.to_i if str.size > 0
      end
    end

    def remove_pid_file
      if self.pid_file && File.exist?(self.pid_file)
        File.delete(self.pid_file)
      end
    end

    def above_cpu_limit?(include_children = true)
      Ziltoid::System.cpu_usage(self.pid, include_children) > self.cpu_limit.to_f
    end

    def above_ram_limit?(include_children = true)
      Ziltoid::System.ram_usage(self.pid, include_children) > self.ram_limit.to_i
    end

    def start
      return if Ziltoid::System.pid_alive?(self.pid)
      %x(#{self.start_command})
    end

    def stop
      if !Ziltoid::System.pid_alive?(self.pid)
        self.remove_pid_file
        return
      else
        %x(#{self.stop_command})
      end
    end

  end
end