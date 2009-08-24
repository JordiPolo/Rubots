=begin
  Rubots
     Copyright(c) 2009  Jordi Polo

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
=end


module RRMi
  class ProcessMonitor

    def initialize(startCmd, processString, success, error)
       @startCmd, @processString, @success, @error = startCmd, processString, success, error
       @pid = nil
    end
   
    #TODO: use signal to know if the process are alive 
    def running?
      !pid.nil?
    end

    def kill 
      if !signal 9
        puts @processString + " couldn't be killed"
      end
    end 

    #TODO: launch even with other launched, need changes in the pid method
    def run 
      if pid.nil?
        start_process
      else
        puts "process " + @processString + " already running, reusing it at pid " + pid 
      end
      @pid = pid
      if @pid.nil?
        raise "process died just after been born, we are desolated"
      end
     end

    def signal(signal_num)
      begin
        Process::kill signal_num, @pid.to_i
      rescue Exception => e
        puts e.message
        return false
      end
      return true
    end

  private
  
    def wait_initialize(pipe, stop_at, error_at)
      while line = pipe.gets
       puts line 
        break if line.include? stop_at
        raise "Gazebo or player couldn't be initialized" if line.include? error_at
      end
      puts line
   #   debug_output pipe
    end
    
    def debug_output (pipe)
    Thread.new do
      while true do 
        while line = pipe.gets
         puts line
        end
      end
     end   
    end    
    
    def pid
      pid = nil
      ps = IO.popen("ps -ef", "r")
      re = Regexp.new(".*?#{@processString}.*?")
      ps.each do | line |
        if re.match(line)
          pid = line.split[1]
        end
      end
      ps.close
      return pid 
    end

    def start_process
      puts "Starting process"
      puts @startCmd
      pipe = IO.popen(@startCmd, "r")
      wait_initialize( pipe, @success, @error )
     # pipe.close
#      @pid_gazebo =pipe_gazebo.pid
#      process = Process.fork { system("#{@restartCmd}") }
#      Process.detach(process)
    end
    

  end

end
