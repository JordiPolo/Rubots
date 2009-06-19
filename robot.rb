require 'playerc'
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
    def initialize (connection, number)
      @gun = Gun.new
      @radar = Radar.new
      @forwardSpeed = 0
      @turningSpeed = 0


      position = Playerc::Playerc_position2d.new(connection, 1)
      if position.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
        raise  Playerc::playerc_error_str()
      end

    end
  
    def speed=(x, yaw)
      @forwardSpeed = [x, yaw]
      position.set_cmd_vel(x, 0.0, yaw * Math::PI / 180.0, 1)
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
