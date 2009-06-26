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
     @robots = []
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
  end
 
  def load
     #read configuration 
     file = "session.yml"
     if not File.exists? file
       raise "The game sesssion file #{file} can not be found" 
     end
     session = YAML::load(File.open(file))
     
     robot_count = 0 
     session['Robots'].each do |robot_file|
       load_robot(robot_file) 
     end

  end


  def load_robot(robot_file)
     puts "loading robot " + robot_file
       if not File.exists? robot_file
         raise "The robot file #{robot_file} can not be found"
       end

       total_bytes = 0
       File.open( robot_file ) do |f|
#TODO: count code size
#       f.each_line {|l| total_bytes += line.size unless line =~ /^\s*($|#)/ }
         f.grep( /class.*<.*Robot/ ) do |line|
           line.gsub!(/ /,'') # strip all the whitespaces
           robot_class = line.slice(5..line.index('<')-1)
           require robot_file
           @robots[robot_count] = eval(robot_class + ".new")
           @robots[robot_count].init(@connection, robot_count +1 ) 
         end
       end
  end

  def mainLoop
    threads = []
    @robots.each do  |r| 
      r.aboutToStart  #run outside the thread so we wait to every robot's start
    end
    @robots.each do |r|
      threads << Thread.new do 
        r.run # robots can enter in busy loop here or setup and become event driven
      end
    end

    while (@running) do
      signal_gazebo_player
      sleep(0.2) 
    end

    threads.each { |aThread|  aThread.kill; aThread.join }

    @robots.each do  |r| 
      r.finished  #run outside the thread so we wait to every robot's start
    end
   
    signal_gazebo_player 15
   
  end

  def finish
    @running = false 
  end

 private
  def wait_initialize(pipe, stop_at, error_at)
    while line = pipe.gets
#      puts line ; puts ""
      break if line.include? stop_at
      raise "Gazebo or player couldn't be initialized" if line.include? error_at
    end
    puts line
  end


# currently not working as they are launched in a sh process that is always living
  def signal_gazebo_player (signal = 0)
      [@pid_gazebo, @pid_player].each do |pid|
#         puts pid
         begin 
           Process::kill signal, pid
         rescue
           puts "Gazebo or Player died, exiting"
           @running = false
         end
       end

  end

 end


end
  
game = Rubots::Game.new
game.init
game.load
game.mainLoop
