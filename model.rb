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
    
    def method_missing(m, *args)
      
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


end


