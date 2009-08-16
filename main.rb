# Brisca
#
# Signare est un serveur de jeu de carte

require "config.rb"
require 'logger'
require "Serveur.rb"

LOG = Logger.new STDERR

LOG.info "Le serveurs est lancé"

h = Mongrel::HttpServer.new("0.0.0.0", PORT_SERVEUR)
h.register("/", ListeParties.new)
h.run.join
