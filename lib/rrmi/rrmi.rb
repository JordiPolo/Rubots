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

require 'connection'

class Float
    def to_rad 
      self * Math::PI / 180.0
    end
    
    def to_degrees
      self * 180.0 / Math::PI 
    end  
end

class Hash
    def to_pose_t
      pose = Playercpp::Player_pose2d_t.new
      pose.px = self[:x]
      pose.py = self[:y]
      pose.pa = toRad self[:yaw]
      return pose
    end  
end



#Ruby Robotics Middleware 
module RRMi
  
    
  
  class CannonIface
    def initialize (index)
      @iface = Playercpp::PtzProxy.new($connection.player, index)
      @iface.SelectControlMode(Playercpp::PLAYER_PTZ_POSITION_CONTROL)
      @pan = 0
      
    end    
    
    def turn (degrees)
      @pan = degrees
      @iface.SetCam( @pan, 0, 0 )  
    end
    
    def angle 
      @iface.GetPan
    end
    
    def shoot (number)
      @iface.SetCam( @pan, 0, number )
    end
  end
  
  #TODO: x, y  and distance are redundant, choose!
  #type, info are placeholders for the upper layer
  class ScannedObject
    attr_accessor :id, :x, :y, :distance, :bearing, :type, :info
  end
  
  class FiducialIface
    def initialize (index)
      puts "fidu index " + index.to_s
      @iface = Playercpp::FiducialProxy.new($connection.player, index)
    end
    
    def dataAvailable
      @iface.GetCount != 0
    end
    
    def find_object
  #    $connection.player.Read
      for i in 1..@iface.GetCount do
         f = @iface.GetFiducialItem(i-1)
     #    puts "object found, id: #{f.id}, x: #{f.pose.px}, y: #{f.pose.py}, angle: #{f.pose.pyaw}"
         object = ScannedObject.new
         object.id = f.id  
         object.x = f.pose.px
         object.y = f.pose.py
         object.distance = Math.sqrt( object.x **2 + object.y **2 )
         object.bearing = f.pose.pyaw
         yield object
      end
    end
    
  end


  
  class PositionIface
    attr_reader :current_velocity
    def initialize (index)
      puts "index " + index.to_s
      @iface = Playercpp::Position2dProxy.new($connection.player, index)
      @ifaceGoto = Playercpp::Position2dProxy.new($connection.player, index+1)
      @controlType = :vel      

      @current_velocity = { :x => 0, :y => 0, :yaw => 0}
      @default_vel = { :x =>1, :y => 1, :yaw =>1 } #random numbers, just to make it move if the user provide no defaults
      @current_pos = @current_velocity
    end
    
    #properties
    def setObjectName (name)
      @realName = name
    end
    # velocity that will be used when commanding positions TODO
    def setDefaultVelocity ( vel )
      @default_vel = vel
    end

    def setVelocity ( vel )
      @controlType = :vel
      @current_velocity.merge! vel 
      puts "new velocity ", @current_velocity
      @iface.SetSpeed(@current_velocity[:x], @current_velocity[:y], toRad( @current_velocity[:yaw] ))
    end
    
    def stop #stop slowly
      return if @controlType == :vel
      stopped = false
      min_vel = 0.04
      while !stopped do  
        stopped = true
        @current_velocity.each { |k, v| @current_velocity[k] = v - (0.001 )  }
        setVelocity  @current_velocity
        @current_velocity.each_value do |v| 
          if v > min_vel  
            stopped = false
          end
        end
        sleep 0.01
      end
      setVel :x => 0, :y => 0, :yaw => 0
    end
    

    def setRelativePosition ( position )
      puts "relative positon: ", position
      position = {:x => 0, :y => 0, :yaw => @current_pos[:yaw]}.merge position
      position[:x] = position[:x] * Math.sin( toRad(position[:yaw] ))
      position[:y] = position[:x] * Math.cos( toRad(position[:yaw] ))
      
      current_pos = getAbsolutePosition
      new_pos = {}
      raise "incorrect positions" if current_pos.nil? or position.nil?
      p "current, position", @current_pos, current_pos, position
      [:x, :y].each do |s|
        new_pos[s] = current_pos[s] + position[s]
      end
      new_pos[:yaw] = position[:yaw] #this is not relative to global
      raise "not working " if new_pos.empty?
      setAbsolutePosition new_pos
      
      
    end

  #TODO: this is a global position?
    def getAbsolutePosition 
      pos = $connection.simulation.GetPose2d @realName
      position = {:x => pos[0] , :y => pos[1], :yaw => toDegrees( pos[2] ) }
    end

    def setAbsolutePosition ( pos )
      @controlType = :pos
      puts "moving to new pos", pos
      position = pose_tFromHash pos
      @current_velocity = { :x => 0, :y => 0, :yaw => 0}
      vel = pose_tFromHash @current_velocity
      @ifaceGoto.GoTo( position, vel )
      @current_pos = pos
    end

   private
   

    def setVel (vel)  
    end
    
    
  end
end