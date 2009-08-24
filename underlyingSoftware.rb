=begin
  RRMi 
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

  
require 'rubygems'
require 'ruby-debug'

require 'forwardable'

require 'processMonitor'
require 'connection'

#Ruby Robotics Middleware 
module RRMi
  
  #class to control Player and Gazebo
  class UnderlyingSoftware
  
    def initialize
      @monitoringProcesses = []
    end

    # opts are:
    # batch_mode : true/false to launch the graphical output or no
    # control_iface: 'gazebo' , 'player'

    def startGazebo (command, batch_mode = false)

      if batch_mode #we dont want to display graphical interface
        gazebo_cmd = "gazebo -r #{command} 2>&1"
      else
        gazebo_cmd = "gazebo #{command} 2>&1"
      end

       # launch gazebo    
      gazeboProcess = ProcessMonitor.new(gazebo_cmd, "gazebo", "successfully", "Exception")
      gazeboProcess.run 
      @monitoringProcesses << gazeboProcess

      puts "Gazebo launched"

#      @gazeboClient = Gazeboc::Client.new

      if !gazeboProcess.running?
        raise "gazebo died"
      end
=begin
      begin 
        @gazeboClient.Connect 0
      rescue Exception => e
        gazeboProcess.kill
        raise e.message 
      end
=end
    end


    def startPlayer(command)
      
      player_cmd = "player #{command} 2>&1"
      puts player_cmd
      playerProcess = ProcessMonitor.new(player_cmd, "player ", "success", "error")
      playerProcess.run 
      @monitoringProcesses << playerProcess

      puts "Launching player"

      retries = 6
      connected = false
      while (!connected) and (retries > 0)
        sleep 1
        begin
          $connection.connect
        rescue 
          retries -= 1
        else
          connected = true
        end
      end  
      if !connected
        cleanup
        raise "we were not able to launch Player"
      end
        
    end 
    

    # if all the processes are running
    def running? 
      @monitoringProcesses.inject(true) {|result, process| result and process.running?}
    end 

    # cleanup all the processes
    def cleanup
      @monitoringProcesses.each{ |p| p.kill}
    end

  end
  
end