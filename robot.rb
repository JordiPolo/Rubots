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


require 'rubygems'
require 'ruby-debug'
require 'radar'
require 'rules'
#require 'gun'


module Rubots


  module Tools
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
    def _init (connection)
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
      @_ifacePosition = nil
   #   @_model = nil
      @energy = Rules::LIFE
    end

    def _init (model)
   
   #   @_model = model
      @_ifacePosition = model.positionIface 
      @name = model.name
      @_ifacePosition.open 
      @_ifacePosition.setDefaultVelocity( Rules::MAX_VELOCITY, Rules::MAX_VELOCITY, Rules::MAX_TURN_RATE)
 
    #  @radar._init(connection)     
      @gun._init(model)
#TODO: fiducial ID
#      @fiducialId = connection.fiducialID
      @radar.add_observer self  #interested in radar events
    end

    #periodic instructions come here
    def _run
      
    end

    def _cleanup 
      @_ifacePosition.cleanup
   #   @radar._cleanup
      @gun._cleanup
    end 
    ###################################
    # Events to be implemented by robots
    ###################################
    def aboutToStart
    end

    def run
   #   @radar.scan()
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
      puts "object found"
    end
    #when anything else is scanned
    def onScannedRobot (robot)
      puts "robot found"
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
       @_ifacePosition.setVelocity(@forwardSpeed, 0.0, @turningSpeed)

    end

    def setTurningSpeed (degrees)
       puts "robot turning " + degrees.to_s 
       @turningSpeed = normalize(degrees, Rules::MAX_API_TURN_RATE, Rules::MAX_TURN_RATE)  
       @_ifacePosition.setVelocity(@forwardSpeed, 0.0, @turningSpeed )
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
      @_ifacePosition.setRelativePosition( meters, 0, 0 )
    end

    def turn (degrees)
      @_ifacePosition.setRelativePosition( 0, 0, degrees )
    end
 
    #absolute position
    def turnTo (degrees)
      pos = @_ifacePosition.getPosition 
      turn( degrees - pos.yaw )
    end


    def worldPosition
      @_ifacePosition.getPosition 
    end 

   private
    include Tools

  end 

end

