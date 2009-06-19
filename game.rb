=begin

  Rubots
     Copyright(c) 2009
     Jordi Polo

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


module Rubots

  class Game
   def initialize
     # launch gazebo    
     @pipe_gazebo = IO.popen("gazebo -r pioneer2dx.world 2>&1", "r")
     wait_initialize(@pipe_gazebo, "successfully", "Exception")

     # launch player
     @pipe_player = IO.popen("player player.cfg 2>&1", "r")
     wait_initialize(@pipe_player, "success", "error")
     @running = true

   end 

   def mainLoop
     while (@running)
       #advance one step in simulation
       #check they didn't die under our feet
 puts "aa"
       [@pipe_gazebo, @pipe_player].each do |pipe|
         puts pipe.pid
         begin 
           puts Process::kill (0, pipe.pid)
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
      raise "Gazebo couldn't be initialized" if line.include? error_at
    end
  end

  end


end

game = Rubots::Game.new
game.mainLoop
