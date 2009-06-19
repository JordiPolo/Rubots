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
require 'yaml'

require 'robot'


module Rubots

  class Game

   def initialize
     @robot1 = nil
     @robot2 = nil
   end

   def init

     #read configuration 
     config_file = "configuration.yml"
     if not File.exists? config_file
       raise "Configuration file #{config_file} can not be found" 
     end
     config = YAML::load(File.open(config_file))

     
     # launch gazebo    
     pipe_gazebo = IO.popen("gazebo -r #{config['gazebo_world']} 2>&1", "r")
     wait_initialize(pipe_gazebo, "successfully", "Exception")
     @pid_gazebo =pipe_gazebo.pid

     # launch player
     pipe_player = IO.popen("player #{config['player_config']} 2>&1", "r")
     wait_initialize(pipe_player, "success", "error")
     @pid_player = pipe_player.pid
     @running = true

    @connection = Playerc::Playerc_client.new(nil, 'localhost', 6665)
    if @connection.connect != 0
      raise Playerc::playerc_error_str()
    end
#    Robot.new(@connection, 1)
#    @robot2 = Robot.new (@connection, 2) 

   end
 
   def load (file)
     #read configuration 
     file = "session.yml"
     if not File.exists? file
       raise "The game sesssion file #{file} can not be found" 
     end
     session = YAML::load(File.open(file))

     robot1_file = session['robot1']
     robot2_file = session['robot2']

     if not File.exists? robot1_file
       raise "The robot file #{robot1_file} can not be found"
     end
     File.open( robot1_file ) do |f|
       f.grep( /class*<*Robot/ ) do |line|
         puts ':', line
         line.gsub(/ /,'') # strip all the whitespaces
         robot1_class = line(5..line.index('<'))
         puts robot1_class
       end
     end
     

   end

   def mainLoop
     while (@running)
       #advance one step in simulation
       #check they didn't die under our feet
       [@pid_gazebo, @pid_player].each do |pid|
#         puts pid
         begin 
           Process::kill (0, pid)
         rescue
           puts "Gazebo or Player died, exiting"
           @running = false
         end
       end
      sleep(0.1) 
     end
   end

   def finish
     @running = false 
   end

  private
   def wait_initialize(pipe, stop_at, error_at)
    while line = pipe.gets
      puts line ; puts ""
      break if line.include? stop_at
      raise "Gazebo or player couldn't be initialized" if line.include? error_at
    end
  end

  end


end

game = Rubots::Game.new
#game.init
game.load
game.mainLoop
