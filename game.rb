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

require 'yaml'
require 'Qt'

require 'connection' 
require 'underlyingSoftware' 
require 'robot' 





module Rubots

  class GameLogic 
    def initialize (robots)
      @robots = robots
    end
  end
 
  class Config
    
    def self.needed?
      not File.exists? "session.yml"
    end
    
    def self.load
      Config.loadFile "session.yml"
    end
    def self.save (data)
      self.saveConfig data, "session.yml"
    end
    
    def self.loadFile (file)
      if not File.exists? file
        raise "The game configuration file #{file} can not be found" 
      end
      YAML::load(File.open(file))
    end
    
    def self.saveConfig (data, file)
      File.open(file, 'w') do |out|
        YAML.dump(data, out)
      end
    end
  end
 
  
  class Game < Qt::Object
    
   def initialize
     super
     @robots = []
     @threads = []
     @running = false
     $connection = RRMi::Connection.new
   end

   def init (batch_mode)
    
     session = Config.load 
    
     #load stadium
     stadium_file = session['stadium']
     stadium_file_prefix = File.dirname( stadium_file ) + '/'
     
     stadium = Config.loadFile stadium_file
          
     @software = RRMi::UnderlyingSoftware.new
     @software.startGazebo( stadium_file_prefix + stadium['gazebo_config'], batch_mode )
     @software.startPlayer( stadium_file_prefix + stadium['player_config'] )
     
     Signal.trap(0, proc { puts "Terminating: #{$$}, killing underlying software"; cleanup })
  #TODO: rules
     loadRobots(session) 
     
  end

  def mainLoop
    Thread.abort_on_exception = true
    @robots.each do  |r| 
      r.onGameStart  #run outside the thread so we wait to every robot's start
    end

    @running = true

    @robots.each do |r|
      @threads << Thread.new do 
        r.run # robots can enter in busy loop here or setup and become event driven
        
      end
    end

    puts "running main loop"
    @updateTimer = Qt::Timer.new( self )
    connect( @updateTimer, SIGNAL('timeout()'), self, SLOT('update()') )
    @updateTimer.start(100)
  end

  #if we are running the update method will be called and eventually cleanup
  #if we are  not running we cleanup ourselves
  def finish
    if @running
      @running = false
    else
      cleanup
    end
  end  

  def robot_by_fiducial (fiducial)
    @robots.each {|r| puts r.fiducialId}
    @robots.find {|r| r.energy > 0 and r.fiducialId == fiducial}
  end
  
  def kill_robot (robot)
    @robots.delete robot
  end

  slots :update
  def update
      $connection.update 
      @robots.each { |r|  r._run } 
      @running = @running and @software.running? 
      if !@running
        @updateTimer.stop
        @threads.each { |aThread|  aThread.kill; aThread.join }
        @robots.each { |r|  r.onGameFinish }   # let the robots to finish themselves
        cleanup 
      end
  end 

      
  def loadRobots(session)
      # Numbering in robots:
      #robot1 - fiducialId = 1 , base_index = 10
      #robot2 - fiducialId = 2 , base_index = 20
      # each robot in the player config file will have 10 slots of interfaces
      # 0 , 10, 20 , 30 as defaults. 
    session['robots'].each_with_index do |robot_file, robot_count|
      puts "loading robot " + robot_file
      if not File.exists? robot_file
        raise "The robot file #{robot_file} can not be found"
      end
      robot = nil
      total_bytes = 0

       File.open( robot_file ) do |f|
#TODO: count code size
#       f.each_line {|l| total_bytes += line.size unless line =~ /^\s*($|#)/ }
         f.grep( /class.*<.*Robot/ ) do |line|
           line.gsub!(/ /,'') # strip all the whitespaces
           robot_class = line.slice(5..line.index('<')-1)
           require robot_file
           robot = eval(robot_class + ".new robot_count")
           if robot.nil?
             raise "No robot could be created from the file"
           end
           @robots << robot
         end
       end #file.open
     end 
  end 

  
  def cleanup
    @robots.each do  |r| 
      r._cleanup  #game internal cleanup of robots
    end
    if not @software.nil?
      @software.cleanup
    end
    Qt::Application.instance.quit
  end
 

 end


end

