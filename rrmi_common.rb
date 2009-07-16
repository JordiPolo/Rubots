=begin
  RRMi 
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

require 'gazeboc'
require 'playerc'
require 'rubygems'
require 'ruby-debug'
require 'forwardable'

require 'processMonitor'
require 'rrmi_connections'

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









end