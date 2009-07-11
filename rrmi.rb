
require 'gazeboc'

require 'rubygems'
require 'ruby-debug'


require 'processMonitor'

#Ruby Robotics Middleware 
module RRMi

  class Command2D

    include Comparable

    attr_accessor :x, :y, :yaw

    def initialize (*args)
      if (args.size == 1)
        @x, @y, @yaw = args[0].x, args[0].y, args[0].yaw
      elsif (args.size == 3)
        @x, @y, @yaw = args[0], args[1], args[2]
      end
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
    def startUnderlyingSoftware(config, batch_mode=false)
      
      if batch_mode #we dont want to display graphical interface
        gazebo_cmd = "gazebo -r #{config['gazebo_world']} 2>&1"
      else
        gazebo_cmd = "gazebo #{config['gazebo_world']} 2>&1"
      end
    
       # launch gazebo    
       @gazeboProcess = ProcessMonitor.new(gazebo_cmd, "gazebo", "successfully", "Exception")
       @gazeboProcess.run 

       puts "Gazebo launched"

       if !@gazeboProcess.running?
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
    attr_reader :name
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
      @default_vel = Command2D.new( 10,10,1 ) #random numbers, just to make it move if the user provide no defaults
    end

    def open
      @iface.Open  @client, @name
    end

    def cleanup
      @iface.Close
    end

 #TODO: this is TOTALLY broken
    def setRelativePosition ( *args )
      #player
      #@_ifacePosition.set_cmd_pose(@position[:x] + meters, @position[:y], @position[:yaw], 1)
      #check the motors
      pos = Command2D.new *args
      #debugger
      puts pos
      stop # basically dont control with vel and pos, choose!
      target_pos = getPosition + pos     
      vel = alingVelPos( @default_vel, pos )
      setVelocity (vel)

      while (target_pos < getPosition)
        puts "pos " + target_pos.to_s + " target " + getPosition.to_s
        sleep (0.01)
      end
      stop
    end

    def setDefaultVelocity ( *args )
      vel = Command2D.new *args
      @default_vel = vel
    end


    def setVelocity (*args)
      #player
      #@iface.set_cmd_vel(@forwardSpeed, 0.0, toRad( @turningSpeed ), 1)
      vel = Command2D.new *args
      with_lock do
        @iface.data.cmdVelocity.pos.x = vel.x
        @iface.data.cmdVelocity.pos.y = vel.y
        @iface.data.cmdVelocity.yaw = vel.yaw #TODO:this is rad or degrees?
      end
      
    end
    
    #TODO: this is a global position?
    def getPosition
      my_pos = Command2D.new( 0, 0, 0 )
      with_lock do
        pose = @iface.data.pose
        my_pos = Command2D.new(pose.pos.x, pose.pos.y, pose.yaw)
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
      [:x, :y, :yaw].each do |cmd|
        if (pos.send(cmd) < 0) and (vel.send(cmd) > 0) or 
           (pos.send(cmd) > 0) and (vel.send(cmd) < 0)
          if cmd == :x 
            final_vel.x = -final_vel.x 
          elsif cmd == :y 
            final_vel.y = -final_vel.y 
          elsif cmd == :yaw 
            final_vel.yaw = -final_vel.yaw 
          end          
        end
      end
      return final_vel
    end

    
  end
end