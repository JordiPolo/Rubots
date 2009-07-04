=begin
  Rubots
     Copyright(c) 2009  Jordi Polo

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
=end

require 'playerc'
require 'rubygems'
require 'ruby-debug'
require 'radar'
require 'rules'
#require 'gun'


module Rubots

  
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




  class Robot
    attr_reader :gun, :radar
    attr_reader :forwardSpeed, :turningSpeed
    attr_reader :name, :energy, :fiducialId

    def initialize
      @gun = Gun.new
      @radar = Radar.new
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
      @fiducialId = ifaceIndex #BIG assumption
      @radar.add_observer(self) #interested in radar events
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
      @radar.scan()
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

    #translate observed events to method name and execute them
    def update (event, object)
      event[0].capitalize! 
      method_name = "on" + event
      eval (method_name + " object")        
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
