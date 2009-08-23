=begin
  Rubots
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

require 'fluentforwardable' #robot info
require 'observer' # events

module Rubots

 
  #info about one robot available to external entities (i.e. other robots)
  class RobotInfo 
    extend Forwardable
    delegate_readers(:name, :energy, :forwardSpeed, :turningSpeed).to(:@r) 
    def initialize (robot)
      @r = robot 
    end
  end 


  class Radar
    include Observable
    def initialize 
   
    end

    def _init (model)
      @_iface = model.fiducialIface
    end

    def _cleanup

    end 

    def scan
      
      @_iface.find_object do |object|
         if Rules::ID_ROBOTS.include? object.id
          #TODO 
           #object.info = RobotInfo.new $engine.robot_from_fiducial(f.id)
          object.type = "robot"
          notify_observers( "scannedRobot", object )
         else
           object.type = "object"
           notify_observers( "scannedObject", object )
         end      
      end

#        f = fiducial.fiducials[i]
#        puts "id, x, y, range, bearing, orientation: ", f.id, f.pos[0], f.pos[1], f.range, f.bearing * 180 / PI, f.orient
#      end
    end

  end

end