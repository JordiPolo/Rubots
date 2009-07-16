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

require 'rrmi_common'



#Ruby Robotics Middleware 
module RRMi

#common to all the Ifaces
  module IfaceConnection
    def init
      @usingPlayer = false
      @iface = nil
      if @connection.using? 'player'
        @usingPlayer = true
        @ifaceNumber = @name.split('::')[0][-1,1] #last character before ::
      end
    end

    def open
      if @usingPlayer
        if @iface.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
          raise  Playerc::playerc_error_str()
        end
      else
        @iface.Open  @connection.gazeboClient, @name
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


#connection to the fiducial Iface
  class FiducialIfaceConnection
    include IfaceConnection
    def initialize (connection, fullname)
      @connection = connection
      @name = fullname
      init
      if @usingPlayer
         @iface = Playerc::Playerc_fiducial.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::FiducialIface.new
      end
    end

  end





#connection to the position iface
  class PositionIfaceConnection
    include IfaceConnection

    def initialize (connection, fullname)
      @connection = connection
      @name = fullname
      init
      if @usingPlayer
         @iface = Playerc::Playerc_position2d.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::PositionIface.new
      end
    end

    def setVel (vel)
      if @usingPlayer
        @iface.set_cmd_vel(vel.x, vel.y, toRad( vel.yaw ))
      else
        with_lock do
          @iface.data.cmdVelocity.pos.x = vel.x
          @iface.data.cmdVelocity.pos.y = vel.y
          @iface.data.cmdVelocity.yaw = vel.yaw #TODO:this is rad or degrees?
        end
      end
    end

    def getPosition
      
      if @usingPlayer
        @connection.read #this is needed?
        my_pos = Command2D.new( @iface.px, @iface.py, @iface.pa ) 
      else
        with_lock do
          pose = @iface.data.pose
          my_pos = Command2D.new(pose.pos.x, pose.pos.y, pose.yaw)
          return my_pos
        end 
      end
    end

  private

    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

  end

end