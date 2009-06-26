require 'robot'

class MyRobot < Rubots::Robot

 def initialize
   name="Test Robot"
 end

#events
    def aboutToStart
  #    speed= , 1
    end

    def run
      speed= 50, 5 
      position = worldPosition
      forward 10
      position2 = worldPosition
      if (position == position2)
        raise "we are not moving"
      end
      forward -10 
      position = worldPosition
      if (position == position2)
        raise "we are not moving"
      end
    
    end

    def gameFinished
    end


end

