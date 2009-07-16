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
require 'connection'
require 'rrmi_common'

#Ruby Robotics Middleware 
module RRMi


  class FiducialIface
    include IfaceConnection
    def initialize (connection, index)
      init connection, index 
#        @ifaceNumber = @name.split('::')[0][-1,1].to_i #last character before ::
      if @usingPlayer
         @iface = Playerc::Playerc_fiducial.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::FiducialIface.new
      end
    end
  end


  class PositionIface
    include IfaceConnection
    def initialize (connection, index)
      init connection, index
      @default_vel = Command2D.new( 10,10,1 ) #random numbers, just to make it move if the user provide no defaults
      if @usingPlayer
         @iface = Playerc::Playerc_position2d.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::PositionIface.new
      end
      @iface_sim = Playerc::Playerc_simulation.new(@connection.playerClient, 0)
        if @iface_sim.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
          raise  Playerc::playerc_error_str()
        end

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


    def setVel (vel)
      puts vel
      if @usingPlayer
        @iface.set_cmd_vel(vel.x, vel.y, toRad( vel.yaw ),1)
      else
        with_lock do
          @iface.data.cmdVelocity.pos.x = vel.x
          @iface.data.cmdVelocity.pos.y = vel.y
          @iface.data.cmdVelocity.yaw = vel.yaw #TODO:this is rad or degrees?
        end
      end
    end

     # TODO make this work on Gazebo backend
    def setRelativePosition(pos)
      my_pos = getPosition
      new_pos = my_pos + pos
      puts "new pos", new_pos
      @iface.set_cmd_pose(new_pos.x,new_pos.y,new_pos.yaw, 1)
    end
    
    def getGlobalPosition
      pos = nil
      pos = @iface_sim.get_pose2d("pioneer2dx_model1")
   #   Command2D.new( pos.px, pos.py, pos.pa )
      Command2D.new( pos[0], pos[1],pos[2] )
    end

    #TODO: this is a global position?
    def getPosition
      return getGlobalPosition
      my_pos = nil
      if @usingPlayer
     #   @connection.playerClient.read #this is needed?
        my_pos = Command2D.new( @iface.px, @iface.py, @iface.pa ) 
      else
        with_lock do
          pose = @iface.data.pose
          my_pos = Command2D.new(pose.pos.x, pose.pos.y, pose.yaw)
        end 
      end
      return my_pos
    end

    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

=begin   
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

=end    
  end
end