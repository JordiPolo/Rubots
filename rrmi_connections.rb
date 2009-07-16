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


# common to all the Ifaces
# Connection classes knows how to connect to the different backends and will only accept 
# RRMI like params so, it is a backend to RRMI layer
# the classes without the connection names are mean to interact with the non RRMI world
  module IfaceConnection
    def init
      @usingPlayer = false
      @iface = nil
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
    def initialize (connection, index)
      @connection = connection
      init
      @ifaceNumber = index 
      @name = index
#        @ifaceNumber = @name.split('::')[0][-1,1].to_i #last character before ::
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

    def initialize (connection, index)
      @connection = connection
      @ifaceNumber = index
      @name = index
      init
      if @usingPlayer
         @iface = Playerc::Playerc_position2d.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::PositionIface.new
      end
    end

    def setVel (vel)
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

    #TODO: this is a global position?
    def getPosition
      my_pos = nil
      if @usingPlayer
        @connection.playerClient.read #this is needed?
        my_pos = Command2D.new( @iface.px, @iface.py, @iface.pa ) 
      else
        with_lock do
          pose = @iface.data.pose
          my_pos = Command2D.new(pose.pos.x, pose.pos.y, pose.yaw)
        end 
      end
      return my_pos
    end

  private

    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

  end

end