require 'playerc'
#require 'gun'
#require 'radar'

module Rubots
  
  module Tools
    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

    def normalize (data, min, max, scale)
      if data < min
        data = min
      end
      if data > max
        data = max
      end
      data = data / scale
      data
    end
  end



  class Gun
     #rotations, fire 
    def initialize
      @bullets = 100
    end

    def fire (number = 1)
      puts "fired #{number} bullets"
      if @bullets < number 
        number = @bullets
      end
      @bullets -= number
    end

   private
    include Tools 
  end


  class Radar
    
  end


  class Robot
    attr_reader :gun, :radar
    attr_reader :forwardSpeed, :turningSpeed
    attr_reader :name, :energy

    def initialize
      @gun = Gun.new
      @radar = Radar.new
      @forwardSpeed = 0
      @turningSpeed = 0
      @name = "Unknown"
      @_ifaceIndex = 0
      @_ifacePosition = nil
      @energy = 100 
    end

    def init (connection, interface_index)
      @_ifaceIndex = interface_index
      @_connection = connection
      @_ifacePosition = Playerc::Playerc_position2d.new(@_connection, @_ifaceIndex)
      if @_ifacePosition.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
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

    def finished
    end

    def onHitByBullet
    end

    def onHitRobot
    end
    
    def onHitObject
    end

    def onScannedRobot
    end

    ##############################
    # Movement
    # Speed commands return inmediately
    # Position commands return after the position is reached
    ##############################
 
    def forwardSpeed= (speed)
       @forwardSpeed = normalize(speed, -100, 100, 10)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end

    def turningSpeed= (degrees)
       @turningSpeed = normalize(degrees, -100, 100, 100)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end 

    def speed= (speed, angle)
      turningSpeed= angle
      forwardSpeed= speed
    end

    def forward (meters)
      updatePosition
      if @forwardSpeed == 0 
        forwardSpeed= 50
      end
      @_ifacePosition.set_cmd_pos(@position[:x] + meters, @position[:y], @position[:yaw], 1)
    end

    def turn (degrees)
      updatePosition
       if @turningSpeed == 0 
         turningSpeed= 50
      end
      @_ifacePosition.set_cmd_pos(@position[:x], @position[:y], @position[:yaw] + toRad( degrees), 1)
    end
 
    #absolute position
    def turnTo (degrees)
      updatePosition
       if @turningSpeed == 0 
         turningSpeed= 50
      end
      @_ifacePosition.set_cmd_pos(@position[:x], @position[:y], toRad( degrees), 1)
    end

       
 
   private
    def updatePosition
       Playerc::Playerc_client_read(@_connection) # this is needed?
       @position = {:x => @_ifacePosition.px, :y => @_ifacePosition.py, :yaw => @_ifacePosition.pa } 
    end
    include Tools

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
