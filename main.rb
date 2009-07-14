require 'logger'
require "Serveur.rb"

LOG = Logger.new STDOUT

LOG.info "Le serveurs est lancé"

h = Mongrel::HttpServer.new("0.0.0.0", "3000")
h.register("/", ListeParties.new)
h.run.join
