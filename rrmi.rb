
require 'gazeboc'

require 'processMonitor'

#Ruby Robotics Middleware 
module RRMi

  class Command2D
    include Comparable
    attr_accessor :x, :y, :yaw
    def initialize (x, y, yaw)
      @x, @y, @yaw = x, y, yaw
    end
    def <=>(second)
      if @x < second.x and @y < second.y and @yaw < second.yaw
        return -1 
      elsif @x > second.x and @y > second.y and @yaw > second.yaw
        return 1
      else 
        return 0
      end
    end
    def + (second)
   #   @x += second.x
   #   @y += second.y
   #   @yaw += second.yaw
      return Command2D.new(@x + second.x, @y + second.y,@yaw + second.yaw)
    end 

    def to_s
      "x: " + @x.to_s + " y: " + @y.to_s + " yaw: " + @yaw.to_s
    end
  end


  class Connection
    def startUnderlyingSoftware(config)

      gazebo_cmd = "gazebo #{config['gazebo_world']} 2>&1"
    
       # launch gazebo    
       @gazeboProcess = ProcessMonitor.new(gazebo_cmd, "gazebo", "successfully", "Exception")
       @gazeboProcess.run 

       puts "Gazebo launched"

       if !@gazeborProcess.running?
         raise "gazebo died"
       end
   
       @client = Gazeboc::Client.new
       @simIface = Gazeboc::SimulationIface.new

      begin 
        @client.Connect 0
      rescue Exception => e
        @gazeboProcess.kill
        raise e.message 
      end
    
    end


    def running?
      @gazeboProcess.running?
    end 

    def cleanup
      @gazeboProcess.kill 
    end

    def getModel (model_name)
      Model.new @client, model_name
    end

  end

  class Model
    
    def initialize (client, name)
      @client = client
      @name = name
    
    end

    def positionIface (name)
      iface_name = @name + "::" + name 
      iface = PositionIface.new @client, iface_name
         
    end
   

  end
  


  class PositionIface
    def initialize (client, fullname)
      @client = client
      @name = fullname
      @iface = Gazeboc::PositionIface.new
      @default_vel = Command2D.new( 10,10.1 ) #random numbers, just to make it move if the user provide no defaults
    end

    def open
      @iface.Open @client, @name
    end

    def cleanup
      @iface.Close
    end
 
    def setRelativePosition (x, y, yaw)
      setRelativePosition( Command2D.new( x,y,yaw ) )
    end
    def setRelativePosition ( pos )
      #player
      #@_ifacePosition.set_cmd_pose(@position[:x] + meters, @position[:y], @position[:yaw], 1)
      #check the motors
      stop # basically dont control with vel and pos, choose!
      target_pos = getPosition + pos     
      vel = alingVelPos (@default_vel, pos)
      setVelocity (vel)

      while (target_pos < getPosition)
        puts "pos " + target_pos.to_s + " target " + getPosition.to_s
        sleep (0.01)
      end
      stop
    end

    def setDefaultVelocity ( x, y, yaw)
      setDefaultVelocity( Command2D.new( x,y,yaw ) )
    end
    def setDefaultVelocity ( vel )
      @default_vel = vel
    end

    def setVelocity ( x, y, yaw)
      setVelocity( Command2D.new( x,y,yaw ) )
    end
    def setVelocity (vel)
      #player
      #@iface.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
      with_lock do
        @iface.data.cmdVelocity.pos.x = vel.x
        @iface.data.cmdVelocity.pos.y = vel.y
        @iface.data.cmdVelocity.pos.yaw = vel.yaw #TODO:this is rad or degrees?
      end
      
    end
    
    #TODO: this is a global position?
    def getPosition
      with_lock do
        pos = @iface.data.pose.pos
        my_pos = Command2D.new(pos.x, pos.y, pos.yaw)
      end 
      return my_pos
    end

    def stop
      setVelocity (Command2D.new(0,0,0))
    end

   private
    def with_lock(&block)
      @iface.Lock 1
      yield
      @iface.Unlock
    end

    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

    
    def alingVelPos( vel, pos )
    #  ['x', 'y', 'yaw'].each do |param|      
      final_vel = vel
      pos.each_with_index do |cmd, i|
        if (cmd < 0) and (vel[i] > 0) or 
           (cmd > 0) and (vel[i] < 0)
        final_vel[i] = -final_vel[i]
        
        end
      end
      return final_vel
    end

    
  end
end