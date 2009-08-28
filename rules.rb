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


#
module Rubots
  class Rules
    attr_reader :MAX_API_VELOCITY
    def useStrict
          @MAX_API_VELOCITY = 100  # max movingspeed
    end
    
    def useArcade
          @MAX_API_VELOCITY = 100  # max movingspeed
    end
    #general
    #limits as seen by the robot implementation
    MAX_API_VELOCITY = 100  # max movingspeed
    MAX_API_TURN_RATE = 100 # max turning speed

    #robots
    #limits in the simulation
    MAX_VELOCITY = 1  # max moving speed
    MAX_TURN_RATE = 10  # max turning speed
    LIFE = 100  # initial energy of robot
    ID_ROBOTS = 1..10 # ids allocated for robots

    #guns
    HIT_DAMAGE = 1 # damage if the robot hit something (or is hit)
    BULLETS = 100  # amount of bullets per robot
    BULLET_DAMAGE = 50 # damage caused by bullet hitting robot
    MAX_GUN_TURN_RATE = 4
  end
end