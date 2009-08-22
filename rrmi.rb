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

=begin
  module IfaceConnection
    def init (connection, index)
      @usingPlayer = false
      @iface = nil
      @ifaceNumber = index 
      @name = index
      @connection = connection
      if @connection.using? 'player'
        @usingPlayer = true
      end
    end

    def open

      if @usingPlayer
        if @iface.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
          raise  Playerc::playerc_error_str()
        end
      else
        @iface.Open  @connection.gazeboClient, @name #if fail, exception
      end
    end

    def cleanup
      if @usingPlayer
        @iface.unsubscribe
      else
        @iface.Close
      end
    end

    def with_lock(&block)
      @iface.Lock 1
      yield
      @iface.Unlock
    end
  end
=end


  class FiducialIface
    def initialize (index)
      @iface = Playercpp::FiducialProxy.new($playerClient, index)
    end
  end


  
  class PositionIface
    attr_reader :current_velocity
    def initialize (index)
      
      @current_velocity = { :x => 0, :y => 0, :yaw => 0}
      @default_vel = { :x =>10, :y => 10, :yaw =>1 } #random numbers, just to make it move if the user provide no defaults
      @iface = Playercpp::Position2dProxy.new($playerClient, index)
      @iface_sim = Playercpp::SimulationProxy.new($playerClient, 0)
      
    end


    # velocity we will use when commanding positions
    def setDefaultVelocity ( vel )
      @default_vel = vel
    end

    def setVelocity ( vel )
      setVel vel
    end
    
    def stop
      setVel  :x => 0, :y => 0, :yaw => 0
    end
=begin
    def setRelativePosition ( *args )
      pos = Command2D.new *args
      current_pos = getPosition
      new_pos = current_pos + pos
      puts "moving to new pos", new_pos
      @iface.set_cmd_pose(new_pos.x,new_pos.y,new_pos.yaw, 1)
    end
=end
  #TODO: this is a global position?
    def getPosition
      @iface_sim.GetPose2d("pioneer2dx_model1")
    end

    def setPosition (*args)
      pos = Command2D.new *args
      @iface_sim.set_pose2d("pioneer2dx_model1", pos.x, pos.y, pos.yaw)
    end

   private


    def setVel (vel)  
      @current_velocity.merge! vel 
      puts "new velocity ", @current_velocity
      
      # TODO: rad or degrees
      @iface.SetSpeed(@current_velocity[:x], @current_velocity[:y], @current_velocity[:yaw])
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