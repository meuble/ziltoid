module Ziltoid

  module System

    # The position of each field in ps output
    PS_FIELD_MAP = {
      :pid => 0,
      :ppid => 1,
      :cpu => 2,
      :ram => 3
    }

    module_function

    def pid_alive?(pid)
      ::Process.kill(0, pid)
      true
    rescue Errno::EPERM # no permission, but it is definitely alive
      true
    rescue Errno::ESRCH
      false
    end

    def ps_aux
      # BSD style ps invocation
      processes = `ps axo pid,ppid,pcpu,rss`.split("\n")

      processes.inject({}) do |result, process|
        info = process.split(/\s+/)
        info.delete_if { |p_info| p_info.strip.empty? }
        info.map! { |p_info| p_info.gsub(",", ".") }
        pid = info[PS_FIELD_MAP[:pid]].strip.to_i
        result[pid] = info.flatten
        result
      end
    end

    def cpu_usage(pid, include_children = true)
      ps = ps_aux
      return unless ps[pid]
      cpu_used = ps[pid][PS_FIELD_MAP[:cpu]].to_f

      get_children(pid).each do |child_pid|
        cpu_used += ps[child_pid][PS_FIELD_MAP[:cpu]].to_f if ps[child_pid]
      end if include_children

      cpu_used
    end

    def get_children(parent_pid)
      child_pids = []
      ps_aux.each_pair do |_pid, info|
        child_pids << info[PS_FIELD_MAP[:pid]].to_i if info[PS_FIELD_MAP[:ppid]].to_i == parent_pid.to_i
      end
      grand_children = child_pids.map { |pid| get_children(pid) }.flatten
      child_pids.concat grand_children
    end

  end

end