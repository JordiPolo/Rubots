require 'playerc'
require 'rubygems'
require 'ruby-debug'
#require 'gun'
#require 'radar'

module Rubots

  class Rules
    #general
    #limits as seen by the robot implementation
    MAX_API_VELOCITY = 100  # max movingspeed
    MAX_API_TURN_RATE = 100 # max turning speed

    #robots
    #limits in the simulation
    MAX_VELOCITY = 10  # max moving speed
    MAX_TURN_RATE = 1  # max turning speed
    LIFE = 100  # initial energy of robot
    ID_ROBOTS = 1..10 # ids allocated for robots

    #guns
    HIT_DAMAGE = 1 # damage if the robot hit something (or is hit)
    BULLETS = 100  # amount of bullets per robot
    BULLET_DAMAGE = 10 # damage caused by bullet hitting robot
    MAX_GUN_TURN_RATE = 4
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
      result = (data * real_limit) / limit
      return result
    end
  end



  class Gun
     #rotations, fire 
    def initialize
      @bullets = Rules::BULLETS
    end
    def _init (connection, interface_index)
    end
    def _cleanup
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

 #TODO: x, y  and distance are redundant, choose!
  class ScannedObject
    attr_accessor :id, :type, :x, :y, :distance, :bearing, :info
  end

  require 'forwardable' 
  #info about one robot available to external entities (other robots)
  class RobotInfo 
    extend Forwardable
    def initialize (robot)
      @r = robot 
    end
    
    def_delegators :@r, :name, :energy, :forwardSpeed, :turningSpeed 
  end 


  class Radar

    def initialize (robot)
      @robot = robot
    end

    def _init (connection, interface_index)
      @_connection = connection
      @_iface = Playerc::Playerc_fiducial.new(@_connection, interface_index)
      if @_iface.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
        raise  Playerc::playerc_error_str()
      end
    end

    def _cleanup
      @_iface.unsubscribe
    end 

    def scan
      @_connection.read
      #puts "fiducial device with #{@_iface.fiducials_count} readings"
      
      if @_iface.fiducials_count == 0
        puts "no readings available in this interface"
      else
#TODO: more than one object found?
#      for i in 0..fiducial.fiducials_count do
         f = @_iface.fiducials
         puts "object found, id: #{f.id}, x: #{f.pose.px}, y: #{f.pose.py}, angle: #{f.pose.pyaw}"
         object = ScannedObject.new
         object.id = f.id  
         object.x = f.pose.px
         object.y = f.pose.py
#         object.distance = 
         object.bearing = f.pose.pyaw
         if Rules::ID_ROBOTS.include? f.id
 #TODO: get robot object from the fiducial id
#         object.robot = RobotInfo.new ()
          @robot.onScannedRobot object
          object.type = "robot"
         else
           object.type = "object"
           @robot.onScannedObject object
         end 

#        f = fiducial.fiducials[i]
#        puts "id, x, y, range, bearing, orientation: ", f.id, f.pos[0], f.pos[1], f.range, f.bearing * 180 / PI, f.orient
#      end
    end

    end
  end


  class Robot
    attr_reader :gun, :radar
    attr_reader :forwardSpeed, :turningSpeed
    attr_reader :name, :energy

    def initialize
      @gun = Gun.new
      @radar = Radar.new self
      @forwardSpeed = 0
      @turningSpeed = 0
      @name = "Unknown"
#      @_ifaceIndex = 0
      @_ifacePosition = nil
      @energy = Rules::LIFE
    end

    def _init (connection, interface_index)
      ifaceIndex = interface_index
      @_connection = connection
      @_ifacePosition = Playerc::Playerc_position2d.new(@_connection, ifaceIndex)
      if @_ifacePosition.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
        raise  Playerc::playerc_error_str()
      end
      @radar._init(connection, ifaceIndex)     
      @gun._init(connection, ifaceIndex)
    end
    
    def _cleanup 
      @_ifacePosition.unsubscribe
      @radar._cleanup
      @gun._cleanup
    end 
    ###################################
    # Events to be implemented by robots
    ###################################
    def aboutToStart
    end

    def run
    end

    def onFinish
    end

    def onHitByBullet
    end

    def onHitRobot
    end
    
    def onHitObject
    end
    #when a robot is scanned
    def onScannedObject (object)
    end
    #when anything else is scanned
    def onScannedRobot (robot)
    end

    ##############################
    # Movement
    # Speed commands return inmediately
    # Position commands return after the position is reached
    ##############################
    #speed
    def setForwardSpeed(speed)
        puts "robot speed " + speed.to_s
       @forwardSpeed = normalize(speed, Rules::MAX_API_VELOCITY, Rules::MAX_VELOCITY)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end

    def setTurningSpeed (degrees)
       puts "robot turning " + degrees.to_s 
       @turningSpeed = normalize(degrees, Rules::MAX_API_TURN_RATE, Rules::MAX_TURN_RATE)  
       @_ifacePosition.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
    end 

    def setSpeed (speed, angle)
      puts "set speed"
      setTurningSpeed  angle
      setForwardSpeed  speed
    end

    def stop 
      setSpeed 0,0
    end

    # movement
    def forward (meters)
      updatePosition
      if @forwardSpeed == 0 
        setForwardSpeed Rules::MAX_API_VELOCITY
      end
      if (meters < 0) and (@forwardSpeed > 0) or 
         (meters > 0) and (@forwardSpeed < 0)
         setForwardSpeed -@forwardSpeed
      end 
      @_ifacePosition.set_cmd_pose(@position[:x] + meters, @position[:y], @position[:yaw], 1)
    end

    def turn (degrees)
      updatePosition
       if @turningSpeed == 0 
         setTurningSpeed Rules::MAX_API_TURN_RATE 
      end
      @_ifacePosition.set_cmd_pose(@position[:x], @position[:y], @position[:yaw] + toRad( degrees), 1)
    end
 
    #absolute position
    def turnTo (degrees)
      updatePosition
       if @turningSpeed == 0 
         setTurningSpeed Rules::MAX_API_TURN_RATE 
      end
      @_ifacePosition.set_cmd_pose(@position[:x], @position[:y], toRad( degrees), 1)
    end


    def worldPosition
      updatePosition
      return @position
    end 

   private
    def updatePosition
       @_connection.read #this is needed?
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
