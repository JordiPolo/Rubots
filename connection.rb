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

require 'gazeboc'
require 'playerc'

require 'rubygems'
require 'ruby-debug'

require 'forwardable'

require 'processMonitor'
require 'rrmi_connections'
require 'rrmi_common'
require 'rrmi'
require 'model'


#Ruby Robotics Middleware 
module RRMi

  class Connection
    attr_reader :gazeboClient, :playerClient
    def initialize
      @usingPlayer = false
      @playerClient = nil
      @gazeboClient = nil
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

      @gazeboClient = Gazeboc::Client.new

      if !gazeboProcess.running?
        raise "gazebo died"
      end

      begin 
        @gazeboClient.Connect 0
      rescue Exception => e
        gazeboProcess.kill
        raise e.message 
      end

    end


    def startPlayer(command)
      @usingPlayer = true
      # launch player
      
      player_cmd = "player #{command} 2>&1"
      puts player_cmd
      playerProcess = ProcessMonitor.new(player_cmd, "player ", "success", "error")
      playerProcess.run 
      @monitoringProcesses << playerProcess

      puts "Player launched"
            
      @playerClient = Playerc::Playerc_client.new(nil, 'localhost', 6665)
     
      retries = 6
      connected = false
      while (!connected) and (retries > 0)
        sleep 1
        if @playerClient.connect == 0
          connected = true 
        end
        retries -= 1
      end
     
      if !connected
        error = Playerc::playerc_error_str()
        cleanup
        raise error
      end
    end 
    

    def update  
      while @playerClient.data_requested == 1
        @playerClient.read
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
    
    def using?(feature)
      if feature == 'player'
        return @usingPlayer
      elsif feature == 'gazebo'
        return true
      else
        return false
      end
    end
 
    #create a new model of this connection with this name and index
    def getModel (model_name, default_index=nil)
      Model.new self, model_name, default_index
    end

  end
end