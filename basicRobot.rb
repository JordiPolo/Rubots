require 'robot'

class TestRobot < Rubots::Robot

 def initialize
   super
   name="Test Robot"
 end

#events
    def aboutToStart
      puts "testrobot about to start"
  #    speed= , 1
    end

    def run
      puts "testrobot running"
      speed = 50, 5 
      initial_position = worldPosition

      forward 10
      sleep 5
      position2 = worldPosition
      if (initial_position == position2)
        raise "we are not moving"
      end
      forward -10 
      sleep 5
      position = worldPosition
      puts "robot moved among " 
      puts  initial_position ,  position2 ,  position
      if (position == position2)
        raise "we are not moving"
      end
      if initial_position != position
        raise "simulation failure"
      end 
    end

    def gameFinished
    end


end

