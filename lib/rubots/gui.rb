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
  require 'korundum4'
  
  require 'gameconfiggui' #generated from ui: rbuic4 configgui.ui -o configgui.rb
  require 'gameoverui'
  
  require 'game'
  
module Rubots
 
  class GameOverGui < Qt::Dialog 
     def initialize
       super 
       @contents = Ui_GameOverDialog.new
       @contents.setupUi(self)
       @contents.buttonBox.connect(SIGNAL :accepted) { accept }
     end
     def setWinner (winner)
       @contents.label_winner.text = "Winner robot: " + winner
     end
     def setStats(data)
       @contents.label_stats.text = data
     end
  end
  
  class GameConfigGui < Qt::Dialog 
    def initialize
      super 
      config = Config.load
      @contents = Ui_Dialog.new
      @contents.setupUi(self)
      
      @contents.stadium_requester.text = config['stadium']
      
      if config['rules'] == 'arcade'
        @contents.rule_arcade.checked = true
      elsif config['rules'] == 'strict'
        @contents.rule_strict.checked = true
      end
      
      config['robots'].each_with_index do |robot_file, robot_count|
        eval( "@contents.robot#{robot_count+1}_requester.text = robot_file" )
      end
      
      @contents.buttonBox.connect(SIGNAL :accepted) { acceptData }
      @contents.buttonBox.connect(SIGNAL :rejected) { rejectData }
    end    
    
    def acceptData
      config = Hash.new
      config['stadium'] = @contents.stadium_requester.text
      config['rules'] = 'arcade' if @contents.rule_arcade.checked
      config['rules'] = 'strict' if @contents.rule_strict.checked
      config['robots'] = Array.new
      config['robots'][0] = @contents.robot1_requester.text
      config['robots'][1] = @contents.robot2_requester.text
      Config.save config
      accept
    end
    
    def rejectData
      reject
    end
    
  end

  
 
   class GameControlPanel < Qt::Widget

    def initialize
      super
      @game = Rubots::Game.new
      $engine = @game
            
      config = Qt::PushButton.new("Configure")
      config.resize(100, 30)
      config.connect(SIGNAL :clicked) { configure }

      @run = Qt::PushButton.new("Run!")
      @run.resize(100, 30)
      @run.connect(SIGNAL :clicked) { run_batch }

      @watch = Qt::PushButton.new("Watch!")
      @watch.resize(100, 30)
      @watch.connect(SIGNAL :clicked) { run_visual }

      quit = Qt::PushButton.new('Quit')
      quit.setFont(Qt::Font.new('Times', 18, Qt::Font::Bold))
      quit.connect(SIGNAL :clicked) { quit_app }
      
      if Config.needed?
        @run.enabled = false
        @watch.enabled = false
      end
      
      layout = Qt::VBoxLayout.new
      layout.addWidget config
      layout.addWidget @run
      layout.addWidget @watch
      layout.addWidget quit
      setLayout layout

    end
    
    
    def configure
      GameConfigGui.new.show
      if Config.needed?
        @run.enabled = false
        @watch.enabled = false
      else
        @run.enabled = true
        @watch.enabled = true
      end
    end
    
    def run_visual
      @game.start false
    end
    
    def run_batch
      @game.start true
    end
    
    def quit_app
      @game.finish
      Qt::Application.instance.quit
    end
    

  end


end
