
#require 'gun'
#require 'radar'

module Rubots

  class Gun
    
  end


  class Radar
    
  end


  class Robot
    attr_reader :gun, :radar
    attr_writer :forwardSpeed, :turningSpeed
    def initialize
      @gun = Gun.new
      @radar = Radar.new
      @forwardSpeed = 0
      @turningSpeed = 0
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
