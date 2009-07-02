require 'robot'

class TestRobot < Rubots::Robot

 def initialize
   name="Test Robot"
 end

#events
    def aboutToStart
  #    speed= , 1
    end

    def run
      puts "runnuunn"
      speed = 50, 5 
      puts "speed"
      position = worldPosition
      initial_position = position
      puts "robot at initial position" + position

      forward 10
      position2 = worldPosition
      if (position == position2)
        raise "we are not moving"
      end
      forward -10 
      position = worldPosition
      puts "robot moved among " + initial_position + "    " + position +  "    "  + position2
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

