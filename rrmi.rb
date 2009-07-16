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

require 'rubygems'
require 'ruby-debug'
require 'forwardable'

require 'processMonitor'
require 'rrmi_connections'
require 'rrmi_common'

#Ruby Robotics Middleware 
module RRMi

#TODO: move this to connections? This makes sense?

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
    def startUnderlyingSoftware(config, popts={})
      opts = {:batch_mode => false}.merge!(popts)
      
      if opts[:batch_mode] #we dont want to display graphical interface
        gazebo_cmd = "gazebo -r #{config['gazebo_config']} 2>&1"
      else
        gazebo_cmd = "gazebo #{config['gazebo_config']} 2>&1"
      end

       if config['use_player'] == true
         @usingPlayer = true
         require 'playerc'
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

      # launch player
      if @usingPlayer
        player_cmd = "player #{config['player_config']} 2>&1"
        puts player_cmd
        playerProcess = ProcessMonitor.new(player_cmd, "player ", "success", "error")
        playerProcess.run 
        @monitoringProcesses << playerProcess

        puts "Player launched"
            
        @playerClient = Playerc::Playerc_client.new(nil, 'localhost', 6665)
     
        retries = 10
        connected = false
        while (!connected) and (retries > 0)
          sleep 1
          if @playerClient.connect == 0
            connected = true 
          end
        end
     
        if !connected
          error = Playerc::playerc_error_str()
          cleanup
          raise error
        end
      end #using player
    
    end


    def running?
      @monitoringProcesses.inject(true) {|result, process| result and process.running?}
    end 

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

    def getModel (model_name)
      Model.new self, model_name
    end

  end



  class Model
    attr_reader :name
    def initialize (connection, name)
      @connection = connection
      @name = name
      @simIface = Gazeboc::SimulationIface.new 
    end

    def fiducialID  #TODO: fix the Ruby bindings to make this work
      @simIface.Open @connection.gazeboClient, "default"
      @simIface.Lock 1
      #@simIface.GetModelFiducialID @name, id 
      @simIface.Unlock
      @simIface.Close #TODO:is this safe?  Or I close other instances?
      #return id
      raise "dont call this"
    end

    def positionIface (name)
      iface_name = @name + "::" + name 
      PositionIface.new @connection, iface_name
    end

    def fiducialIface (name)
      iface_name = @name + "::" + name 
      FiducialIface.new @connection, iface_name
    end
  end


  class FiducialIface
    extend Forwardable
    def_delegators :@iface, :open, :cleanup

    def initialize (client, fullname)
      @iface = FiducialIfaceConnection.new client, fullname
    end

  end

  class PositionIface
    extend Forwardable
    def_delegators :@iface, :open, :cleanup

    def initialize (client, fullname)
#       @client = client
#       @name = fullname
      @iface = PositionIfaceConnection.new client, fullname
      @default_vel = Command2D.new( 10,10,1 ) #random numbers, just to make it move if the user provide no defaults
    end

 #TODO: this is TOTALLY broken
    def setRelativePosition ( *args )
      #player
      #@_ifacePosition.set_cmd_pose(@position[:x] + meters, @position[:y], @position[:yaw], 1)
      #check the motors
      pos = Command2D.new *args
      #debugger
      puts pos
      stop # basically dont control with vel and pos, choose!
      target_pos = getPosition + pos     
      vel = alingVelPos( @default_vel, pos )
      setVelocity (vel)

      while (target_pos < getPosition)
        puts "pos " + target_pos.to_s + " target " + getPosition.to_s
        sleep (0.01)
      end
      stop
    end

    def setDefaultVelocity ( *args )
      vel = Command2D.new *args
      @default_vel = vel
    end


    def setVelocity (*args)
      @iface.setVel Command2D.new *args
    end
    
    #TODO: this is a global position?
    def getPosition
      my_pos = Command2D.new( 0, 0, 0 )
      my_pos = @iface.getPosition
      return my_pos
    end

    def stop
      setVelocity (Command2D.new(0,0,0))
    end

   private

    
    def alingVelPos( vel, pos )
    #  ['x', 'y', 'yaw'].each do |param|      
      final_vel = vel
      [:x, :y, :yaw].each do |cmd|
        if (pos.send(cmd) < 0) and (vel.send(cmd) > 0) or 
           (pos.send(cmd) > 0) and (vel.send(cmd) < 0)
          if cmd == :x 
            final_vel.x = -final_vel.x 
          elsif cmd == :y 
            final_vel.y = -final_vel.y 
          elsif cmd == :yaw 
            final_vel.yaw = -final_vel.yaw 
          end          
        end
      end
      return final_vel
    end

    
  end
end