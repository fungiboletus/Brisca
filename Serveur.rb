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
			p = JSON.parse Base64.decode64 CGI::unescape request.params["QUERY_STRING"]
		else
			p = {}
		end

		LOG.debug p
		sleep 1	
	
		# Liste des parties demandées
		if !p["id_joueur"] || p["id_joueur"].to_i == 43 || !p['action']

			obj = []

			$parties.each do |id, partie|
				json = {
					"id" => id,
					"nom"=> partie.nom,
					"organisateur"=> partie.organisateur.nom,
					"id_organisateur"=>partie.organisateur.id,
					"niveau"=>partie.organisateur.niveau,
					"element"=>partie.organisateur.element
				}

				if partie.mdp.nil?
					json["mdp"] = false 
				else
					json["mdp"] = true
				end

				obj.push json
			end
		
			ecrire JSON.pretty_generate(obj), response
			return
		end

		# Récupération de l'id de joueur
		id_joueur = p["id_joueur"].to_i
		joueur = $joueurs[id_joueur]

		if joueur.nil?
			joueur = Joueur.new id_joueur
			$joueurs[id_joueur] = joueur
		end

		# En fonction de ce qu'il faut faire
		case p["action"]
		
		# Si il faut créer une nouvelle partie
		when "nouvelle_partie"
			if p["nom_partie"] && joueur.partie.nil?
				partie = Partie.new $parties.size, p["nom_partie"], p["motdepasse"], joueur				
				$parties[partie.id] = partie
			end

		# Si l'organisateur veut se reconnecter à sa partie
		when "connexion_organisateur"
			if joueur.partie
				joueur.partie.informerOrganisateur
			end
		
		# Si un joueur veut se connecter à une partie déjà organisée
		when "connexion_adversaire"
			if !joueur.partie
			
				partie = $parties[p["id_partie"].to_i]
				
				# Vérification du mot de passe si il y en a un
				if partie.mdp && partie.mdp != ""
					LOG.debug "Protection par mot de passe: #{partie.mdp} vs #{p["motdepasse"]}"	
					if partie.mdp == p["motdepasse"]
						partie.nouveauJoueur joueur
					else
						message =  {
							"connexion_partie" => false
						}

						joueur.pile = [ message ]
						
					end
				else
					partie.nouveauJoueur joueur
				end

			end

		# Pour quand l'organisateur est en attente
		when "attente_adversaire"
			if !joueur.partie
				return
			end

		# Quand l'organisateur refuse ou accepte un adversaire
		when "confirmation_adversaire"
			if joueur.partie && joueur.partie.joueur_b_temp
				if p["decision"]
					joueur.partie.confirmerJoueur
				else
					puts "C'est con"
				end
			end
		else
			LOG.warn "L'action demandée n'a pas été trouvée"
		end
		
		ecrire JSON.pretty_generate(joueur.getPile), response

	end

	def ecrire(texte, rq)
		rq.start(200) do |head,out|
			head["Content-Type"] = "text/plain"
			out.write texte
		end
	end

end

