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

module Rubots
  #class to load and save the files in yaml format we useful
  #used for the session.yml file of every game and the .stadium
  #files that define the battle ground
  class Config
    def self.file
      "session.yml"
    end
    
    def self.needed?
      not File.exists? Config.file
    end
    
    def self.load
      Config.loadFile Config.file
    end
    def self.save (data)
      self.saveConfig data, Config.file
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
 
end  