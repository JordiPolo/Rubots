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

require 'fluentforwardable'
require 'rubygems'
require 'ruby-debug'
require 'radar'
require 'gun'
require 'rrmi'
require 'rules'



module Rubots


  module Tools
    def normalize (data, limit, real_limit)
      if data < -limit
        data = -limit
      end
      if data > limit
        data = limit
      end
      result = (data * real_limit).to_f / limit
      return result
    end
  end





  class Robot
    extend Forwardable
    attr_reader :gun, :radar, :energy, :name, :fiducialId, :base_index
    #attr_reader :forwardSpeed, :turningSpeed
    #delegate_readers(:name, :fiducialId).to(:@_model)
    #delegate_reader(:current_velocity).as(:forwardSpeed).to(:@_ifacePosition)
    
    def initialize
      @forwardSpeed = 0
      @turningSpeed = 0
      @name = "Unknown"
      @_ifacePosition = nil
      @energy = Rules::LIFE
      
    end

    def _init (options)
      @name = options[:name]
      @base_index = options[:base_index]
      @fiducialId = options[:fiducialId]
                        
      @_ifacePosition = RRMi::PositionIface.new @base_index 
      @_ifacePosition.setDefaultVelocity :x => Rules::MAX_VELOCITY, :y => Rules::MAX_VELOCITY, :yaw => Rules::MAX_TURN_RATE

      @gun = Gun.new @base_index
      @radar = Radar.new @base_index
      @radar.add_observer self  #interested in radar events
    end

    #periodic instructions from the engine come here
    def _run
      @radar.scan()
    end
#TODO: empty method
    def _cleanup 
      @radar._cleanup
      @gun._cleanup
    end 
    
    def _hit (bullets)
      @energy -= bullets * Rules::BULLET_DAMAGE
      if @energy <= 0 
        $engine.kill_robot self
        stop
        onDeath
      end
      onHitByBullet
    end
    ###################################
    # Events to be implemented by robots
    ###################################
    def onGameStart
    end

    def run
      
    end
    
    def onGameFinish
    end

    def onDeath
      puts "I have been killed!"
    end

    def onHitByBullet
    end
=begin
    def onHitRobot
    end
    
    def onHitObject
    end
=end
    #when a robot is scanned
    def onScannedObject (object)
   #   puts "object found "  + object.id.to_s
    end
    #when anything else is scanned
    def onScannedRobot (robot)
      puts "robot found"
      puts "robot found"
      puts "robot found"
      puts "robot found"
    end

    #translate observed events to method name and execute them
    def update (event, object)
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
       forwardSpeed = normalize(speed, Rules::MAX_API_VELOCITY, Rules::MAX_VELOCITY)  
       @_ifacePosition.setVelocity :x => forwardSpeed

    end

    def setTurningSpeed (degrees)
       puts "robot turning " + degrees.to_s 
       turningSpeed = normalize(degrees, Rules::MAX_API_TURN_RATE, Rules::MAX_TURN_RATE)  
       @_ifacePosition.setVelocity :yaw => turningSpeed
    end 

    def setSpeed (speed, angle)
      puts "set speed"
      setTurningSpeed  angle
      setForwardSpeed  speed
    end

    # TODO: how to use delegate_reader for these?
    def forwardSpeed 
      @_ifacePosition.current_velocity[:x]
    end
    def turningSpeed 
      @_ifacePosition.current_velocity[:yaw]
    end

    def stop 
      @_ifacePosition.stop
    end
    
    def test
      ein = 4
      nose = $connection.simulation.GetProperty(name, "fiducial_id", ein, 5)
      p nose
    end
    # movement
=begin
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

=end
    def worldPosition
      @_ifacePosition.getPosition 
    end 

   private
    include Tools

  end 

end

