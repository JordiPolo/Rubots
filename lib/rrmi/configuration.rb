=begin
  RRMI
     Copyright(c) 2010  Jordi Polo

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


module RRMi

  #the configuration file of RRMi
  class Configuration    
    def self.load (file)
      if not File.exists? file
        raise "The game configuration file #{file} can not be found" 
      end
      YAML::load(File.open(file))
    end
    
    def self.save (data, file)
      File.open(file, 'w') do |out|
        YAML.dump(data, out)
      end
    end
  end
  
end
 