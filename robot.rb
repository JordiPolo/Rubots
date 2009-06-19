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
    attr_reader :forwardSpeed, :turningSpeed
    attr_accessor :name

    def initialize
      @gun = Gun.new
      @radar = Radar.new
      @forwardSpeed = 10
      @turningSpeed = 0
      @name = "Unknown"
    end

    def init (connection, interface_index)
      @_interface = interface_index
      @_position = Playerc::Playerc_position2d.new(connection, @_interface)
      if position.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
        raise  Playerc::playerc_error_str()
      end
    end

    ###################################
    # Events to be implemented
    ###################################
    def aboutToStart
    end

    def run
    end

    def gameFinished
    end

    ##############################
    # Movement
    ##############################

    def turningSpeed= (angle)
       @turningSpeed = normalize(angle, -30, 30)  
       @_position.set_cmd_vel(@forwardSpeed, 0.0, @turningSpeed * Math::PI / 180.0, @_interface)
    end 
 
    def forwardSpeed= (speed)
       @forwardSpeed = normalize(speed, -30, 30)  
       @_position.set_cmd_vel(@forwardSpeed, 0.0, @turningSpeed * Math::PI / 180.0, @_interface)
    end
=begin 
    def turningSpeed 
      @_turningSpeed
    end    

    def forwardSpeed 
      @_forwardSpeed
    end    
=end

    def speed= (speed, angle)
      turningSpeed= angle
      forwardSpeed= speed
    end


    private
    def normalize (data, min, max)
      if data < min
        data = min
      end
      if data > max
        data = max
      end
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
