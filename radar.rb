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

require 'rubygems'
require 'ruby-debug'
require 'fluentforwardable' #robot info
require 'observer' # events
require 'robot'
require 'rrmi'


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
    def initialize (index) 
      @_iface = RRMi::FiducialIface.new index 
    end


    def _cleanup

    end 

    def scan
      found_objects = []
      @_iface.find_object do |object|
         if Rules::ID_ROBOTS.include? object.id
          #TODO find a robot with a fiducial
           object.info = RobotInfo.new $engine.robot_by_fiducial(object.id)
           object.type = :robot
           event = "ScannedRobot"
         else
           object.type = :object
           event = "ScannedObject"
         end      
         found_objects << object
         changed
         notify_observers( event, object )
      end
      return found_objects
    end

  end

end