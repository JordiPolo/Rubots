require 'playerc'
#require 'gun'
#require 'radar'

module Rubots

  class Rules
    #limits as seen by the robot implementation
    MAX_API_VELOCITY = 100  # max movingspeed
    MAX_API_TURN_RATE = 100 # max turning speed
    #limits in the simulation
    MAX_VELOCITY = 10  # max moving speed
    MAX_TURN_RATE = 1  # max turning speed
    LIFE = 100  # initial energy of robot
    HIT_DAMAGE = 1 # damage if the robot hit something (or is hit)
    BULLETS = 100  # amount of bullets per robot
    BULLET_DAMAGE = 10 # damage caused by bullet hitting robot
  end

  
  module Tools
    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

    def normalize (data, limit, real_limit)
      if data < -limit
        data = -limit
      end
      if data > limit
        data = limit
      end
      data = data * (real_limit / limit)
      data
    end
  end



  class Gun
     #rotations, fire 
    def initialize
      @bullets = Rules::BULLETS
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
      @energy = Rules::LIFE
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
       @forwardSpeed = normalize(speed, Rules::MAX_API_VELOCITY, Rules::MAX_VELOCITY)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end

    def turningSpeed= (degrees)
       @turningSpeed = normalize(degrees, Rules::MAX_API_TURN_RATE, Rules::MAX_TURN_RATE)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end 

    def speed= (speed, angle)
      turningSpeed= angle
      forwardSpeed= speed
    end

    def forward (meters)
      updatePosition
      if @forwardSpeed == 0 
        forwardSpeed= Rules::MAX_VELOCITY / 2
      end
      @_ifacePosition.set_cmd_pos(@position[:x] + meters, @position[:y], @position[:yaw], 1)
    end

    def turn (degrees)
      updatePosition
       if @turningSpeed == 0 
         turningSpeed= Rules::MAX_TURN_RATE / 2
      end
      @_ifacePosition.set_cmd_pos(@position[:x], @position[:y], @position[:yaw] + toRad( degrees), 1)
    end
 
    #absolute position
    def turnTo (degrees)
      updatePosition
       if @turningSpeed == 0 
         turningSpeed= Rules::MAX_TURN_RATE / 2
      end
      @_ifacePosition.set_cmd_pos(@position[:x], @position[:y], toRad( degrees), 1)
    end

    def worldPosition
      updatePosition
      return @position
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
