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

require 'robot'

class TestRobot < Rubots::Robot

 def initialize (index)
   super index
   self.name = "random moves"
 end

#events
    def onStart
      puts "testrobot about to start"
    end

    def run
 #     turn 180
=begin
      initial_position = worldPosition
      puts "position random" , initial_position
      while true
      5.times do 
        setSpeed (20, 40 + rand(60))
        sleep 1 
      end
      stop
      sleep 3
    
      5.times do 
        setSpeed (-20, 40 + rand(60))
        sleep 1 
      end
      end
           # setSpeed (0, -100)
=end
=begin
      stop
      initial_position = worldPosition
      puts "initial positon", initial_position
      puts "testrobot running"
      puts 
      puts
      sleep 1
      #setSpeed 100, 0
      p "turn"
      #forward 2
      turn 135
      sleep 5
      p "forward"
      #setSpeed 80, 0
      #turn 0
      forward (3) 
      
     # turn 30
      sleep 20
      p "turn2"
      p "forward"
      forward 2

      sleep 10
      stop
      sleep 4 
      setSpeed 1,0
      sleep  5
      stop
     # gun.turn 180 * Math::PI / 180.0
#       p gun.angle
#       
#       sleep 6
#       gun.shoot 80
      
      sleep 15
#       position2 = worldPosition
#       p "pos1 ", initial_position
#       p "pos2", position2
#       if (initial_position == position2)
#         raise "we are not moving"
#       end
puts "stopping"      
      stop 
      sleep 10
      puts "moving backwards"
      setSpeed 0,0
#      forward -10 
      sleep 20
      position = worldPosition
      puts "robot moved among " 
      puts  initial_position ,  position2 ,  position
      if (position == position2)
        raise "we are not moving"
      end
      stop
      if initial_position != position
        raise "simulation failure"
      end 
=end
    end

    def onScannedRobot (info)
      puts "WWAAAAAAAAAATA"
      puts info.id, info.x , info.y, info.distance, info.bearing
      gun.turn info.bearing
      if (info.bearing - gun.angle < 3 or info.bearing - gun.angle > -3)
        puts "shooting"
  #      gun.shoot 1
      end
    end


end

=begin
     public void run() {
         while (true) {
             ahead(100);
             turnGunRight(360);
             back(100);
             turnGunRight(360);
         }
     }
  
     public void onScannedRobot(ScannedRobotEvent e) {
         fire(1);
     }

=end
