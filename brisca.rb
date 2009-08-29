#!/usr/bin/ruby
# Brisca
#
# Signare est un serveur de jeu de carte

require "config.rb"
require 'logger'
require "Serveur.rb"

LOG = Logger.new STDERR

LOG.info "Le serveurs est lancé"

Thread.new do
	h = Mongrel::HttpServer.new("0.0.0.0", PORT_SERVEUR)
	h.register("/", ListeParties.new)
	h.run.join
end

puts "Je suis à l'écoute de tout ce que tu demandes mon amour"

loop do

	STDOUT.print "> "
	STDOUT.flush
	
	commande = gets.chomp

	case commande

	when "q"
		puts "C'est pas sympa de me quitter :'("

		exit
	when "lol"
		puts "Oui, c'est rigolo"

	when "jtm"
		puts "Moi aussi je t'aime"

	else
		puts "Désolé, mais \"#{commande}\", je ne sais pas ce que c'est ^^'"
	
	end
end
