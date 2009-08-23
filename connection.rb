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

require 'playercpp'
require 'model'


#Ruby Robotics Middleware 
module RRMi

  class Connection
    attr_reader :player, :simulator
    def initialize
      @simIface = nil
    end
    
    def connect  
      @player = Playercpp::PlayerClient.new('localhost')
    end
    
    def simulation
      if @simIface.nil?
        @simIface= Playercpp::SimulationProxy.new(@player, 0)
      end
      @simIface
    end
    
    def update
      if @player.Peek(0)
        @player.Read
      end
    end
    
    #create a new model of this connection with this name and index
    def createModel (model_name, default_index=nil)
      Model.new model_name, default_index
    end

  end
  
  
end