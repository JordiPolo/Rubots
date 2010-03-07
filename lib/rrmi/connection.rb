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
require 'configuration'
require 'underlyingSoftware' 


#Ruby Robotics Middleware 
module RRMi

  class Connection
    attr_reader :player, :simulator
    
    def initialize
      @simIface = nil
      @software = RRMi::UnderlyingSoftware.new
      Thread.abort_on_exception = true
    end
    
    def start (file, options)
      file_prefix = File.dirname( file ) + '/'
      configuration = Configuration.load file
    
      @software.startGazebo( file_prefix + configuration['gazebo_config'], options[:batch_mode] )
      @player = @software.startPlayer( file_prefix + configuration['player_config'] )
      Signal.trap(0, proc { puts "Terminating: #{$$}, killing underlying software"; finish })
      
    end
    
    def finish
      @software.cleanup
    end
        
    def running? 
      @software.running?
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
    
  end
  
  
end