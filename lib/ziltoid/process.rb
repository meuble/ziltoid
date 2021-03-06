module Ziltoid
  class Process
    attr_accessor :name, :ram_limit, :cpu_limit, :start_command, :stop_command, :restart_command, :pid_file, :start_grace_time, :stop_grace_time, :ram_grace_time, :cpu_grace_time, :restart_grace_time

    WAIT_TIME_BEFORE_CHECK = 1.0
    ALLOWED_STATES = ["started", "stopped", "restarted", "above_cpu_limit", "above_ram_limit"]
    PREDOMINANT_STATES = ["started", "stopped", "restarted"]

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

      if options[:grace_times]
        self.start_grace_time = options[:grace_times][:start] || 0
        self.stop_grace_time = options[:grace_times][:stop] || 0
        self.restart_grace_time = options[:grace_times][:restart] || 0
        self.ram_grace_time = options[:grace_times][:ram] || 0
        self.cpu_grace_time = options[:grace_times][:cpu] || 0
      end
    end

    def pid
      if self.pid_file && File.exist?(self.pid_file)
        str = File.read(pid_file)
        str.to_i if str.size > 0
      end
    end

    def alive?
      Ziltoid::System.pid_alive?(self.pid)
    end

    def dead?
      !alive?
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
      Ziltoid::System.ram_usage(self.pid, include_children) > self.ram_limit.to_i * 1024
    end

    def state
      state_hash = Ziltoid::Watcher.read_state[self.name]
      state_hash["state"] if state_hash
    end

    def updated_at
      state_hash = Ziltoid::Watcher.read_state[self.name]
      state_hash["updated_at"] if state_hash
    end

    def processable?(target_state)
      current_state = self.state
      # started, stopped and restarted are 'predominant' current states,
      # we never proceed unless the corresponding grace time is over
      Watcher.log("Current state : #{current_state} - updated_at : #{self.updated_at.to_i} - target_state : #{target_state}")
      return false if pending_grace_time?
      return true if PREDOMINANT_STATES.include?(target_state)

      # above_cpu_limit and above_ram_limit grace times are different,
      # they represent a time a process has to be in that state to actually be processed (restarted most likely)
      case target_state
      when "above_cpu_limit"
        current_state == target_state && self.updated_at.to_i < Time.now.to_i - self.cpu_grace_time.to_i
      when "above_ram_limit"
        current_state == target_state && self.updated_at.to_i < Time.now.to_i - self.ram_grace_time.to_i
      end
    end

    def pending_grace_time?
      current_state = self.state
      PREDOMINANT_STATES.include?(current_state) && self.updated_at.to_i > Time.now.to_i - self.send("#{current_state.gsub(/p?ed/, '')}_grace_time").to_i
    end

    def update_state(state)
      process_states = Ziltoid::Watcher.read_state
      return nil unless ALLOWED_STATES.include?(state)
      memoized_process_state = process_states[self.name]

      process_states[self.name] = {
        "state" => state,
        "updated_at" => memoized_process_state && memoized_process_state["state"] == state ? memoized_process_state["updated_at"].to_i : Time.now.to_i
      }
      Ziltoid::Watcher.write_state(process_states)
    end

    def watch!
      Watcher.log("Ziltoid is watching process #{self.name}")
      if !alive?
        Watcher.log("Process #{self.name} is dead", Logger::WARN)
        return start!
      end
      if above_cpu_limit?
        update_state("above_cpu_limit") unless pending_grace_time?
        if processable?("above_cpu_limit")
          Watcher.log("Process #{self.name} is above CPU limit (#{self.cpu_limit.to_f})", Logger::WARN)
          return restart!
        end
      end
      if above_ram_limit?
        update_state("above_ram_limit") unless pending_grace_time?
        if processable?("above_ram_limit")
          Watcher.log("Process #{self.name} is above RAM limit (#{self.ram_limit.to_f})", Logger::WARN)
          return restart!
        end
      end
    end

    def start!
      return if Ziltoid::System.pid_alive?(self.pid)
      return unless processable?("started")

      Watcher.log("Ziltoid is starting process #{self.name}", Logger::WARN)
      remove_pid_file
      system(self.start_command)
      update_state("started")
    end

    def stop!
      return unless processable?("stopped")

      Watcher.log("Ziltoid is stoping process #{self.name}", Logger::WARN)
      memoized_pid = self.pid

      if dead?
        remove_pid_file
      else

        Thread.new do
          system(self.stop_command)
          sleep(WAIT_TIME_BEFORE_CHECK)
          if alive?
            system("kill #{memoized_pid}")
            sleep(WAIT_TIME_BEFORE_CHECK)
            if alive?
              system("kill -9 #{memoized_pid}")
              sleep(WAIT_TIME_BEFORE_CHECK)
            end
          end
          if dead?
            remove_pid_file
            update_state("stopped")
          end
        end.join

      end
    end

    def restart!
      return unless processable?("restarted")

      Watcher.log("Ziltoid is restarting process #{self.name}", Logger::WARN)
      alive = self.alive?

      if alive && self.restart_command
        update_state("restarted")
        return system("#{self.restart_command}")
      end

      stop! if alive
      return start!
    end

  end
end
