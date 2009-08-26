require 'robot'

class MyRobot < Rubots::Robot

 def initialize(index)
   super index
   self.name="my second robot"
 end

#events
    def aboutToStart
      
    end

    def run
      initial_position = worldPosition
      puts "position robot2" , initial_position

    end

    def gameFinished
    end

end

