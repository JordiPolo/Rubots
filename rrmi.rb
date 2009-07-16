require 'gazeboc'
require 'rubygems'
require 'ruby-debug'
require 'forwardable'

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
    attr_reader :gazeboClient, :playerClient
    # opts are:
    # batch_mode : true/false to launch the graphical output or no
    # control_iface: 'gazebo' , 'player'
    def startUnderlyingSoftware(config, popts={})
      opts = {:batch_mode => false, :control_iface => 'gazebo'}.merge!(popts)
      
      @usingPlayer = false
      @playerClient = nil

      @monitoringProcesses = []

      if opts[:batch_mode] #we dont want to display graphical interface
        gazebo_cmd = "gazebo -r #{config['gazebo_world']} 2>&1"
      else
        gazebo_cmd = "gazebo #{config['gazebo_world']} 2>&1"
      end
       
      if opts['control_iface'] == 'player'
        @usingPlayer = true
      end
      

       # launch gazebo    
      gazeboProcess = ProcessMonitor.new(gazebo_cmd, "gazebo", "successfully", "Exception")
      gazeboProcess.run 
      @monitoringProcesses << gazeboProcess

      puts "Gazebo launched"

      @gazeboClient = Gazeboc::Client.new
  #    @simIface = Gazeboc::SimulationIface.new

      if !gazeboProcess.running?
        raise "gazebo died"
      end

      begin 
        @gazeboClient.Connect 0
      rescue Exception => e
        gazeboProcess.kill
        raise e.message 
      end

      # launch player
      if @usingPlayer
        player_cmd = "player #{config['player_config']} 2>&1"
        playerProcess = ProcessMonitor.new(player_cmd, "player ", "success", "error")
        playerProcess.run 
        @monitoringProcesses << playerProcess

        puts "Player launched"
            
        @playerClient = Playerc::Playerc_client.new(nil, 'localhost', 6665)
     
        retries = 10
        connected = false
        while (!connected) and (retries > 0)
          sleep 1
          if @playerClient.connect == 0
            connected = true 
          end
        end
     
        if !connected
          error = Playerc::playerc_error_str()
          cleanup
          raise error
        end
      end #using player
    
    end


    def running?
      @monitoringProcesses.inject(true) {|result, process| result and process.running?}
    end 

    def cleanup
      @monitoringProcesses.each{ |p| p.kill}
    end

    def using?(feature)
      if feature == 'player'
        return @usingPlayer
      elsif feature == 'gazebo'
        return true
      else
        return false
      end
    end

    def getModel (model_name)
      Model.new self, model_name
    end

  end



  class Model
    attr_reader :name
    def initialize (connection, name)
      @connection = connection
      @name = name
      @simIface = Gazeboc::SimulationIface.new 
    end

    def fiducialID   #TODO: fix the Ruby bindings to make this work
      @simIface.Open @connection.gazeboClient, "default"
      @simIface.Lock 1
      #@simIface.GetModelFiducialID @name, id 
      @simIface.Unlock
      @simIface.Close #TODO:is this safe?  Or I close other instances?
      #return id
      raise "dont call this"
    end

    def positionIface (name)
      iface_name = @name + "::" + name 
      iface = PositionIface.new @connection, iface_name
    end

    def fiducialIface (name)
      iface_name = @name + "::" + name 
      iface = FiducialIface.new @connection, iface_name
      #Playerc::Playerc_fiducial.new(@_connection, interface_index)
      #if @_iface.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
      #  raise  Playerc::playerc_error_str()
      #end
    end
  end

  module IfaceConnection
    def init
      @usingPlayer = false
      @iface = nil
      if @connection.using? 'player'
        @usingPlayer = true
        @ifaceNumber = @name.split('::')[0][-1,1] #last character before ::
      end
    end

    def open
      if @usingPlayer
        if @iface.subscribe(Playerc::PLAYER_OPEN_MODE) != 0
          raise  Playerc::playerc_error_str()
        end
      else
        @iface.Open  @connection.gazeboClient, @name
      end
    end

    def cleanup
      if @usingPlayer
        @iface.unsubscribe
      else
        @iface.Close
      end
    end

    def with_lock(&block)
      @iface.Lock 1
      yield
      @iface.Unlock
    end
  end

  class FiducialIfaceConnection
    include IfaceConnection
    def initialize (connection, fullname)
      @connection = connection
      @name = fullname
      init
      if @usingPlayer
         @iface = Playerc::Playerc_fiducial.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::FiducialIface.new
      end
    end

  end


  class FiducialIface
    def initialize (client, fullname)
#      @client = client
#      @name = fullname
      @iface = FiducialIfaceConnection.new client, fullname
    end

    def open
      @iface.open 
    end

    def cleanup
      @iface.cleanup
    end

  end


  class PositionIfaceConnection
    include IfaceConnection

    def initialize (connection, fullname)
      @connection = connection
      @name = fullname
      init
      if @usingPlayer
         @iface = Playerc::Playerc_position2d.new(@connection.playerClient, @ifaceNumber)
      else
        @iface = Gazeboc::PositionIface.new
      end
    end

    def setVel (vel)
      if @usingPlayer
        @iface.set_cmd_vel(vel.x, vel.y, toRad( vel.yaw ))
      else
        with_lock do
          @iface.data.cmdVelocity.pos.x = vel.x
          @iface.data.cmdVelocity.pos.y = vel.y
          @iface.data.cmdVelocity.yaw = vel.yaw #TODO:this is rad or degrees?
        end
      end
    end

    def getPosition
      
      if @usingPlayer
        @connection.read #this is needed?
        my_pos = Command2D.new( @iface.px, @iface.py, @iface.pa ) 
      else
        with_lock do
          pose = @iface.data.pose
          my_pos = Command2D.new(pose.pos.x, pose.pos.y, pose.yaw)
          return my_pos
        end 
      end
    end

  private

    def toRad (degrees)
      rad = degrees * Math::PI / 180.0
      rad
    end

  end


  class PositionIface
    extend Forwardable
    def_delegators :@iface, :open, :cleanup

    def initialize (client, fullname)
      @client = client
      @name = fullname
      @iface = PositionIfaceConnection.new client, fullname
      @default_vel = Command2D.new( 10,10,1 ) #random numbers, just to make it move if the user provide no defaults
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
      @iface.setVel vel    
    end
    
    #TODO: this is a global position?
    def getPosition
      my_pos = Command2D.new( 0, 0, 0 )
      my_pos = @iface.getPosition
      return my_pos
    end

    def stop
      setVelocity (Command2D.new(0,0,0))
    end

   private

    
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