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

#Ruby Robotics Middleware 
module RRMi

  class Model
    attr_reader :name
    def initialize (connection, name, default_index)
      @connection = connection
      @name = name
      @default_index = default_index
      puts "default index  " + default_index.to_s
  #    @simIface = Gazeboc::SimulationIface.new 
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
    

    def positionIface (iface_index = nil)
      PositionIface.new @connection, getIndex( iface_index )
    end

    def fiducialIface (iface_index = nil)
      FiducialIface.new @connection, getIndex( iface_index )
    end

  private 
    def getIndex (iface_index)
      if iface_index.class == "String"
        index = @name + "::" + name 
      else
        index = iface_index || @default_index
      end
    end
  end


  class FiducialIface
    extend Forwardable
    def_delegators :@iface, :open, :cleanup
    def initialize (client, index)
      @iface = FiducialIfaceConnection.new client, index
    end
  end


  class PositionIface
    extend Forwardable
    def_delegators :@iface, :open, :cleanup, :getPosition

    def initialize (client, index)
      @iface = PositionIfaceConnection.new client, index
      @default_vel = Command2D.new( 10,10,1 ) #random numbers, just to make it move if the user provide no defaults
    end

 #TODO: this is TOTALLY broken
    def setRelativePosition ( *args )

      #TODO check the motors
      pos = Command2D.new *args
      @iface.setRelativePosition (pos)
=begin
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
=end
    end

    # velocity we will use when commanding positions
    def setDefaultVelocity ( *args )
      vel = Command2D.new *args
      @default_vel = vel
    end

    def setVelocity (*args)
      @iface.setVel Command2D.new *args
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