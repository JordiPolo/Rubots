require 'robot'

class MyRobot < Rubots::Robot

 def initialize(index)
   super index
   name="Test Robot"
 end

#events
    def aboutToStart
      speed= 10, 1
    end

    def run
    end

    def gameFinished
    end

end

