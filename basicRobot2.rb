require 'robot'

class MyRobot < Rubots::Robot

 def initialize(index)
   super index
   self.name="Robot2"
 end

#events
    def aboutToStart
      
    end

    def run
      initial_position = worldPosition
      puts "position robot2" , initial_position
      sleep 1
      setSpeed (60, 100)
=begin
      absolute( { :x => 0, :y => 0, :yaw => 60})
      sleep 4
      absolute( { :x => 0, :y => 0, :yaw => 0})
      sleep 4
      absolute( { :x => 3, :y => 0, :yaw => 0})
      #absolute initial_position
=end
      
    end

    def gameFinished
    end

end

