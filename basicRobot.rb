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

  printf("stepTime wd angleRateL R [%f %f %f %f]\n", stepTime, wd, joints[LEFT]->GetAngleRate(), joints[RIGHT]->GetAngleRate());
  printf("d1 d2 dr da [%f %f %f %f]\n",d1, d2, dr, da);
  printf("pos 0 1 2 vel 0 1 2  [%f %f %f %f %f %f]\n", odomPose[0], odomPose[1], odomPose[2], odomVel[0], odomVel[1], odomVel[2]);



=end

require 'robot'

class TestRobot < Rubots::Robot

 def initialize
   super
   name = "Test Robot"
 end

#events
    def aboutToStart
      puts "testrobot about to start"
  #    speed= , 1
    end

    def run
      stop
      puts "testrobot running"
      initial_position = worldPosition
#      stop
      setSpeed 100, 0
#      forward 10
      sleep 10
      position2 = worldPosition
      if (initial_position == position2)
        raise "we are not moving"
      end
      stop 
      sleep 10
      puts "moving backwards"
      setSpeed -10,0
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
    end

    def gameFinished
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