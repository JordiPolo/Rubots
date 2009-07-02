
module Rubots
  class ProcessMonitor

    def initialize(name, processString, restartCmd)
      @name, @processString, @restartCmd = name, processString, restartCmd
    end

    def get_process_list
      @ps = IO.popen("ps -ef", "r")
    end

    def is_running?
      re = Regexp.new(".*?#{@processString}.*?")
      @ps.each do | line |
        if re.match(line)
          return true
        end
      end
      return false
    end

    def restart_process
      puts "Process  is not running.  Trying to restart."
      process = Process.fork { system("#{@restartCmd}") }
      Process.detach(process)
    end

    def run
      get_process_list
      if !is_running?
        restart_process
      end
    end

  end

end
