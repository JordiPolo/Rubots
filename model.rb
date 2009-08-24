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
  GNU General Public License for mCore details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
=end
=begin
require 'rrmi'

#Ruby Robotics Middleware 
module RRMi

  #old glory, needed to connect with gazebo 
  class Model
    attr_reader :name
    attr_accessor :fiducialId
    
    def initialize ( name, default_index)
      @name = name
      @default_index = default_index
    end
    
    
    def positionIface (iface_index = nil)
      PositionIface.new  getIndex( iface_index )
    end

    def fiducialIface (iface_index = nil)
      FiducialIface.new  getIndex( iface_index )
    end
    
    def cannonIface (iface_index = nil)
      CannonIface.new  getIndex( iface_index )
    end
    
    
    
  private 
    def getIndex (iface_index)
      if iface_index.class == "String"
        raise "WHOOOOO UUUSSSSSES this?"
        index = @name + "::" + iface_index
      else
        index = iface_index || @default_index
      end
    end
  end


end
=end

