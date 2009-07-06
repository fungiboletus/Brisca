require 'rubygems'
require 'mongrel'
require 'json/ext'
require "jcode"
require "cgi"
require 'base64'

$KCODE = 'u'

require 'Partie.rb'
require 'Joueur.rb'

$parties = {}
$joueurs = []

class ListeParties < Mongrel::HttpHandler
	
	def process(request, response)
		# Traitement des paramètres
		if request.params["QUERY_STRING"]
			#p CGI::unescape(request.params["QUERY_STRING"])
			#p Base64.decode64 CGI::unescape request.params["QUERY_STRING"]
			p = JSON.parse Base64.decode64 CGI::unescape request.params["QUERY_STRING"]
			#p = Mongrel::HttpRequest.query_parse request.params["QUERY_STRING"]
		else
			p = {}
		end

		#p request.params["QUERY_STRING"]
		p p
		sleep 1	
		# Liste des parties demandées
		if !p["id_joueur"] || p["id_joueur"].to_i != 42 || !p['action']

			obj = []

			$parties.each do |id, partie|
				json = {
					"id" => id,
					"nom"=> partie.nom,
					"organisateur"=> partie.organisateur,
					"niveau"=>partie.niveau_organisateur,
					"element"=>partie.element_organisateur
				}

				if partie.mdp.nil?
					json["mdp"] = false 
				else
					json["mdp"] = true
				end

				obj.push json
			end
		
			ecrire JSON.pretty_generate(obj), response
			#ecrire $parties.to_json, response
			return
		end

		# Récupération de l'id de joueur
		id_joueur = p["id_joueur"].to_i
		joueur = $joueurs[id_joueur]

		if joueur.nil?
			joueur = Joueur.new id_joueur
			$joueurs[id_joueur] = joueur
		end

		# Si il faut créer une nouvelle partie
		if p["action"] == "nouvelle_partie" && p["nom_partie"]
			partie = Partie.new $parties.size, p["nom_partie"], p["motdepasse"], joueur				
			$parties[partie.id] = partie

		end
		
		ecrire JSON.pretty_generate(joueur.getPile), response

		#$joueurs[id_joueur] = joueur
#		ecrire p.to_json, response
	end

	def ecrire(texte, rq)
		rq.start(200) do |head,out|
			out.write texte
		end
	end

end
joueurs = []


puts "Le serveur est lancé"
h = Mongrel::HttpServer.new("0.0.0.0", "3000")
h.register("/", ListeParties.new)
h.run.join
