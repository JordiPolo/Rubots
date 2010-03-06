#!/usr/bin/ruby -w
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

require 'gui'

  if $0 == __FILE__
    about = KDE::AboutData.new("Rubots", "Rubots", KDE.ki18n(""), "0.1")
    KDE::CmdLineArgs.init(ARGV, about)
    a = KDE::Application.new()
    main = Rubots::GameControlPanel.new
    main.show
    a.exec
  end
