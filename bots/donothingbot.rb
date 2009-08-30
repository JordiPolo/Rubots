require 'robot'

class MyRobot < Rubots::Robot

 def initialize(index)
   super index
   self.name="DoNothing"
 end


    def run
      initial_position = worldPosition
      puts "position donothing" , initial_position
      
    end

end

