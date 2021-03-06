#!/usr/bin/env ruby
# Driver permettant d'executer des actions en fonction des lectures réalisées surle mirror,
# En accord avec le fichier de configuration.
# 
# Author::    	dos Santos Pedro  (pedro.d2.santos@gmail.com)
# Copyright:: 	Copyright (c) 2010 - dos Santos Pedro.
# Date:: 	15 avril 2010
# Version::	1.0
# :title: 	DriverMirror.rb 
#-----------------------------------------------------------------------------------------------------------
#
#   Copyright (C) 2010 dos Santos Pedro
# 
#   This file is part of OpenMirror.
# 
#   OpenMirror is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Lesser General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   OpenMirror is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Lesser General Public License for more details.
# 
#   You should have received a copy of the GNU Lesser General Public License
#   along with OpenMirror.  If not, see <http://www.gnu.org/licenses/>.
#
#-----------------------------------------------------------------------------------------------------------
begin Dir.chdir(File.join(File.dirname(__FILE__), "..")); $ROOTPATH = Dir.pwd; end unless defined? $ROOTPATH

__PATH__        = File.join(File.dirname(__FILE__),"")
__LIBPATH__     = File.join($ROOTPATH, "lib","")
__CONFIGPATH__  = File.join($ROOTPATH, "config","")
__GUIPATH__     = File.join($ROOTPATH, "gui","")

#Chargement des librairies nécéssaires
begin
  require __LIBPATH__ + 'Mirror.rb'
  require __LIBPATH__ + 'Tag.rb'
  require __LIBPATH__ + 'Action.rb'
  require __LIBPATH__ + 'Event.rb'
  require __GUIPATH__ + 'GlobalGui.rb'
  include OpenMirror
rescue LoadError => exception  
  librairie = exception.to_s.gsub("no such file to load -- ", '')  
  puts "-----------------------------------------------------------------------------"
  puts "   Une erreur s'est produite lors du chargement des librairies.              "
  puts "   La librairie \"#{librairie}\" n'a pas été trouvée sur votre système.      "
  puts "   Veuillez l'installer et relancer le programme, Merci.                     "
  puts "-----------------------------------------------------------------------------"
  puts ""
  exit
end


#Liste des options disponnibles
OPTIONS =   {
              "--verbose" 	=> false,
              "--multimirror" 	=> false
            }

#Configuration des événements
EVENT_CONFIGURATION_FILE = __CONFIGPATH__ + "events.yml"

#Delais  des popups
BIG_DELAY_POPUP = 10000

#Définition de l'usage du programme en console
def usage
  puts "-----------------------------------------------------------------------------"
  puts "Usage: ruby DriverMirror.rb <OPTIONS>                                        "
  puts "   OPTIONS:                                                                  "
  puts "            --verbose : Active le mode verbeux                               "
  puts "            --multimirror : Active le mode de lecture sur                    "
  puts "                              plusieurs périphériques simultanés             "
  puts "-----------------------------------------------------------------------------"
  puts ""
  exit
end

#Scanne pour déterminer les mirrors existants
def scanForMirrors
  begin
    #Détéction si plusieurs mirrors sont connectés
    listeMirrors = Mirror.mirrors
    
    #Message d'avertissement si plusieurs mirrors sont connectés et que le mode multimirror
    # n'est pas activé
    if OPTIONS["--verbose"] and !OPTIONS["--multimirror"] then
      if listeMirrors.size > 1 then
	puts "-----------------------------------------------------------------------------"
	puts "/!\\ Attention plusieurs mirrors ont été détectés sur votre machine"
	puts "Seule le premier sera utilisé pour la lecture."
	puts ""
	puts "Pour activer une lecture sur tous les périphériques, veuillez activer"
	puts "l'option --multimirror."
	puts "-----------------------------------------------------------------------------"
	puts ""
      end
    end
    return listeMirrors
  rescue Mirror::MirrorError
      message = "Attention, Aucun mirror détecté!\n Veuillez vérifier vos branchements USB, et relancer le programme "
      app = Qt::Application.new(ARGV)
      win = OpenMirror::PopupGui.new(message, app, true, nil, BIG_DELAY_POPUP)
      win.show
      app.exec
      
    if OPTIONS["--verbose"] then      
      puts "-----------------------------------------------------------------------------"
      puts " #{message}                "
      puts "-----------------------------------------------------------------------------"
      puts ""
    end
  rescue Exception => exception
    if OPTIONS["--verbose"] then
      puts "-----------------------------------------------------------------------------"
      puts " Erreur : " + exception.message
      puts ""
      puts exception.backtrace
      puts "-----------------------------------------------------------------------------"
      puts ""
    end
    
    #Signaler au programme appellant qu'une erreur à été rencontrée
    exit(-1)
  end
end


# Charge les différents événements configurés dans le fichier events.yml
def loadEventsFromConfig
  begin
    
    Event.setConfiguration(EVENT_CONFIGURATION_FILE)
        
  rescue Errno::ENOENT
    
      message = "Impossible de charger le fichier de configuration.\n fichier introuvable, ou vous n'avez pas les droits de\n lecture sur le fichier. (" + EVENT_CONFIGURATION_FILE.to_s + ")"
      app = Qt::Application.new(ARGV)
      win = OpenMirror::PopupGui.new(message, app, true, nil, BIG_DELAY_POPUP)
      win.show
      app.exec
      
    if OPTIONS["--verbose"] then      
      puts "-----------------------------------------------------------------------------"
      puts " #{message}                "
      puts "-----------------------------------------------------------------------------"
      puts ""
    end
    
  rescue Exception => exception
    if OPTIONS["--verbose"] then
      puts "-----------------------------------------------------------------------------"
      puts " Erreur : " + exception.message
      puts ""
      puts exception.backtrace
      puts "-----------------------------------------------------------------------------"
      puts ""
    end

    #Signaler au programme appellant qu'une erreur à été rencontrée
    exit(-1)
  end
end


#Methode qui va lire le mirror en boucle, et lancer des actions en fonction
# du tag lu.
def readMirror(mirror)
  
  #Ouverture du mirror
  begin 
    mirror.open
  rescue Mirror::MirrorError 
    message = "Impossible d'ouvrir le mirror.\nVous ne disposez peut-être pas des droits nécéssaires,\n ou le périphérique est occupé par un autre programme."
    app = Qt::Application.new(ARGV)
    win = OpenMirror::PopupGui.new(message, app, true, nil, BIG_DELAY_POPUP)
    win.show
    app.exec
    
    if OPTIONS["--verbose"] then      
      puts "-----------------------------------------------------------------------------"
      puts " #{message}                                                                  "
      puts "-----------------------------------------------------------------------------"
      puts ""
    end

  rescue Errno::EPERM 
    message = " Erreur : Impossible d'ouvrir le mirror \n Vous ne disposez pas des droits suffisants pour accéder au périphérique"
    app = Qt::Application.new(ARGV)
    win = OpenMirror::PopupGui.new(message, app, true, nil, BIG_DELAY_POPUP)
    win.show
    app.exec
    
    if OPTIONS["--verbose"] then      
      puts "-----------------------------------------------------------------------------"
      puts " #{message}                                                                  "
      puts "-----------------------------------------------------------------------------"
      puts ""
    end
   
  rescue Exception => exception
    if OPTIONS["--verbose"] then
      puts "-----------------------------------------------------------------------------"
      puts " Erreur : " + exception.message
      puts ""
      puts exception.backtrace
      puts "-----------------------------------------------------------------------------"
      puts ""
    end

    #Signaler au programme appellant qu'une erreur à été rencontrée
    exit(-1)
  end
  
  #Boucle infinie de lecture 
  while true do
 
    #Lecture bloquante sur le mirror
    begin
      
      tagRead = mirror.read
        
    rescue Interrupt 
      if OPTIONS["--verbose"] then
	puts "---------------------------------------------------------------------------"
	puts " Driver interrompu par CTRL + C                                              "
	puts "-----------------------------------------------------------------------------"
	puts ""
      end
      
      #quitter
      exit
      
    rescue ArgumentError, Errno::ENODEV
      message = " /!\\ Attention un mirror à été débranché."
      app = Qt::Application.new(ARGV)
      win = OpenMirror::PopupGui.new(message, app, true, nil, BIG_DELAY_POPUP)
      win.show
      app.exec
    
      if OPTIONS["--verbose"] then      
        puts "-----------------------------------------------------------------------------"
        puts " #{message}                                                                  "
        puts "-----------------------------------------------------------------------------"
        puts ""
      end
      return nil
         
    rescue Exception => exception
      if OPTIONS["--verbose"] then
	puts "-----------------------------------------------------------------------------"
	puts " Erreur : " + exception.message
	puts ""
	puts exception.backtrace
	puts "-----------------------------------------------------------------------------"
	puts ""
      end
    
    end
    
    #Traitement post-lecture
    begin
      
      #Comparaison entre le tag lu et les évents de la configuration
      event = Event.match(tagRead)
      
      if event.nil? then
        message =  " * Aucun événement lancé car aucun ne correspond au tag lu."
      else
        message =  " * Evénement lancé : " + event.to_s
      end
      
      app = Qt::Application.new(ARGV)
      win = OpenMirror::PopupGui.new(message, app, true)
      win.show
      app.exec
    
      if OPTIONS["--verbose"] then      
        puts "-----------------------------------------------------------------------------"
        puts " #{message}                                                                  "
        puts "-----------------------------------------------------------------------------"
        puts ""
      end
      
     
    rescue Exception => exception
      if OPTIONS["--verbose"] then
	puts "-----------------------------------------------------------------------------"
	puts " Erreur : " + exception.message
	puts ""
	puts "-----------------------------------------------------------------------------"
	puts ""
      end
    end
  end
end


#Analyser les paramètres pour déterminer les options.
ARGV.each do |option|
  if OPTIONS.has_key?(option) then
    OPTIONS[option] = true 
  else
    puts option
    usage
  end
end

if OPTIONS["--verbose"] then
  puts "-----------------------------------------------------------------------------"
  puts "                         Driver du Mirror en exécution                       "
  puts "-----------------------------------------------------------------------------"
  puts ""
end

#Scan des mirrors connectés
listeMirrors = scanForMirrors

#Chargement des événements configurés
loadEventsFromConfig

#Liste des threads
listeThreads = []

#Lecture sur les mirror connectés
if OPTIONS["--multimirror"] then
  listeMirrors.each do |device|
    listeThreads << Thread.new {readMirror(device)}
  end
  listeThreads << Thread.new {readMirror(device)}
 
else  
  listeThreads << Thread.new {readMirror(Mirror.mirrors.first)}
end

#Attente sur l'ensemble des threads lancés
listeThreads.each do |thread|
  thread.join
end

#Quitter
exit
