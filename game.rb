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

require 'rubygems'
require 'ruby-debug'



module Rubots

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
     if not File.exists? session_file
       raise "The game sesssion file #{session_file} can not be found" 
     end

     config = YAML::load(File.open(config_file))
     session = YAML::load(File.open(session_file))

     @conn = RRMi::Connection.new
     @conn.startGazebo( config['gazebo_config'], true )

     if config['use_player']
       @conn.startPlayer( config['player_config'] )
     end


     Signal.trap(0, proc { puts "Terminating: #{$$}, killing underlying software"; cleanup })

      
      #WARNING: we assume here an order in the files. TODO
      #We assume that the config, the world and the session file has the same order
      #and based on the same numbers
      # each robot in the player config file will have 10 slots of interfaces
      # 0 , 10, 20 , 30 as defaults. 
     session['Robots'].each_with_index do |robot_file, robot_count|
       robot = load_robot(robot_file)
       robot_name = config['Robots'][robot_count] 
       puts "robot name " + robot_name
       robot_model = @conn.getModel(robot_name, robot_count * 10)
       robot._init( robot_model ) 
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
    connect( @updateTimer, SIGNAL('timeout()'), self, SLOT('update()') )
    @updateTimer.start(500)
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
           @robots << robot
           return robot
         end
       end
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
