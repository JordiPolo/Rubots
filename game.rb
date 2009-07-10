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


require 'yaml'
require 'Qt'

require 'robot'
require 'rrmi'





module Rubots

  class RobotConnection 
    def initialize (model, interface)
      @model = model
      @interface_index = interface
    end
    #def method_missing
    #end
    def positionIface
      name = "position_" + @interface_index.to_s
      @model.positionIface name
    end
  end


  class Game < Qt::Object

   def initialize
     super
     @robots = []
     @threads = []
     @running = false
   end

   def init
     #read configuration 
     config_file = "configuration.yml"
     session_file = "session.yml"

     if not File.exists? config_file
       raise "Configuration file #{config_file} can not be found" 
     end
     config = YAML::load(File.open(config_file))
     
     @conn = RRMi::Connection.new
     @conn.startUnderlyingSoftware config

     Signal.trap(0, proc { puts "Terminating: #{$$}, killing Gazebo"; cleanup })

     if not File.exists? file
       raise "The game sesssion file #{session_file} can not be found" 
     end
     session = YAML::load(File.open(session_file))
      
      #WARNING: we assume here an order in the files. 
      #We assume that the config, the world and the session file has the same order
      #and based on the same numbers
     # robot_count = 0
     session['Robots'].each_with_index do |robot_file, robot_count|
       robot = load_robot(robot_file)
       robot.name = config['Robots'][robot_count] 
       robot_model = RobotConnect.new( @conn.getModel(robot.name), robot_count *2 )
       robot._init( robot_model ) # 0, 2, 4
      # robot_count += 1 
     end

  end

  def mainLoop
    Thread.abort_on_exception = true
    @robots.each do  |r| 
      r.aboutToStart  #run outside the thread so we wait to every robot's start
    end

    @running = true

    @robots.each do |r|
      @threads << Thread.new do 
        r.run # robots can enter in busy loop here or setup and become event driven
      end
    end

    puts "running main loop"
    @updateTimer = Qt::Timer.new( self )
    connect( @updateTimer, SIGNAL('timeout()'),
                          self, SLOT('update()') )
    @updateTimer.start(500)
  end

  #if we are running the update method will be called and eventually cleanup
  #if we are not running we cleanup ourselves
  def finish
    if @running
      @running = false
    else
      cleanup
    end
  end  

  def robot_from_fiducial (fiducial)
    @robots.find {|r| r.fiducialId == fiducial}
  end 


  slots :update
  def update
      @running = @running and @conn.running? 
      if !@running
        @updateTimer.stop
        @threads.each { |aThread|  aThread.kill; aThread.join }
        @robots.each { |r|  r.onFinish }   # let the robots to finish themselves
        cleanup 
      end
  end 


  def load_robot(robot_file)
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
           robot = eval(robot_class + ".new")
           if robot.nil?
             raise "No robot could be created from the file"
           end
          # robot.send(:super)
           #TODO: check we really have a correct thing here
   #        robot._init( @connection, robot_count *2 ) # 0, 2, 4
           @robots << robot
         end
       end
       return robot
  end

  
  def cleanup
    @robots.each do  |r| 
      r._cleanup  #game internal cleanup of robots
    end
    @conn.cleanup
    Qt::Application.instance.quit
  end
 

 end


  
class GameControlWidget < Qt::Widget

  def initialize()
    super
    game = Rubots::Game.new
    $engine = game
    game.init
    game.load
    run = Qt::PushButton.new("Run!")
    run.resize(100, 30)
    run.connect(SIGNAL :clicked) { game.mainLoop }
    quit = Qt::PushButton.new('Quit')
    quit.setFont(Qt::Font.new('Times', 18, Qt::Font::Bold))
    quit.connect(SIGNAL :clicked) { game.finish }
    layout = Qt::VBoxLayout.new
    layout.addWidget(run)
    layout.addWidget(quit)
    setLayout(layout)
  end

end


end

a = Qt::Application.new(ARGV)
  main = Rubots::GameControlWidget.new
  main.show
a.exec
