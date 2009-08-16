require 'rubygems'
require 'mongrel'
require 'json/ext'
require "jcode"
require "cgi"
require 'base64'

require 'Partie.rb'
require 'Joueur.rb'

$parties = {}
$joueurs = {}

class ListeParties < Mongrel::HttpHandler
	
	def process(request, response)

		# Traitement des paramètres
		if request.params["QUERY_STRING"]
			p = JSON.parse Base64.decode64 CGI::unescape request.params["QUERY_STRING"]
		else
			p = {}
		end

		LOG.debug p
	
		# Liste des parties demandées
		if !p["session"] || !p['action'] || p['action'] == 'liste_parties'
			obj = []

			$parties.each do |id, partie|
				if partie.danslaliste	
					json = {
						"id" => id,
						"nom"=> partie.nom,
						"organisateur"=> partie.organisateur.nom,
						"id_organisateur"=>partie.organisateur.id,
						"niveau"=>partie.organisateur.niveau,
						"element"=>partie.organisateur.element
					}

					if partie.mdp.nil? || partie.mdp == ''
						json["mdp"] = false 
					else
						json["mdp"] = true
					end

					obj.push json
				end
			end
		
			ecrire JSON.pretty_generate(obj), response
			return
		end

		# Récupération de l'id de joueur
		session = p["session"]
		joueur = $joueurs[session]

		if joueur.nil?
			joueur = Joueur.new session
			$joueurs[session] = joueur
		end

		return if joueur.invalide

		# Le joueur est toujours en vie
		joueur.enVie

		# En fonction de ce qu'il faut faire
		case p["action"]
		
		# Si il faut créer une nouvelle partie
		when "nouvelle_partie"
			if p["nom_partie"] && joueur.partie.nil?
				partie = Partie.new $parties.size, p["nom_partie"], p["motdepasse"], joueur				
				$parties[partie.id] = partie
			end

		# Si l'organisateur veut se reconnecter à sa partie
		# when "connexion_organisateur"
		#		if joueur.partie
		#		joueur.partie.informerOrganisateur
		# end
		
		# Si un joueur veut se connecter à une partie déjà organisée
		when "connexion_adversaire"
			if !joueur.partie
			
				partie = $parties[p["id_partie"].to_i]

				if !partie.refus.include? joueur.id
					# Vérification du mot de passe si il y en a un
					if partie.mdp && partie.mdp != ""
						LOG.debug "Protection par mot de passe: #{partie.mdp} vs #{p["motdepasse"]}"	
						if !(partie.mdp == p["motdepasse"] && (partie.nouveauJoueur joueur))
							message =  {
								"connexion_partie" => "mdp_faux"
							}

							joueur.pile = [ message ]
							
						end
					else
						if !(partie.nouveauJoueur joueur)
							message =  {
								"connexion_partie" => "place_prise"
							}

							joueur.pile = [ message ]
						end
					end
				else
							message =  {
								"connexion_partie" => "refus_partie"
							}

							joueur.pile = [ message ]
				end
			end

		# Pour quand l'organisateur est en attente
		when "attente_adversaire"
			if !joueur.partie
				return
			end
			joueur.nadalol

		when "attente_organisateur"
			# Rien à faire
			joueur.nadalol
	
		when "attente_action_adversaire"
			joueur.nadalol

		# Quand l'organisateur refuse ou accepte un adversaire
		when "confirmation_adversaire"
			if joueur.partie && joueur.partie.joueur_b_temp
				if p["decision"]
					joueur.partie.confirmerJoueur
				else
					
					partie = joueur.partie

					joueur_b = partie.joueur_b_temp

					pile = joueur_b.pile.clone

					partie.annulerjoueur

					joueur_b.pile = pile

					message = {
						"decision_organisateur" => false
					}

					joueur_b.pile.push message
				end
			end

		when "changement_carte"
			if joueur.partie && p["id_nouvelle_carte"]
				joueur.partie.changerCarte(joueur, p["id_nouvelle_carte"])
			end
		
		when "attaquer"
			if joueur.partie
				joueur.partie.attaquer joueur
			end
		
		else
			LOG.warn "L'action demandée n'a pas été trouvée"
		end
		
		# Savoir où l'on en est dans la partie
		joueur.getStatusPartie
	
		ecrire JSON.pretty_generate(joueur.getPile), response

	end

	def ecrire(texte, rq)
		rq.start(200) do |head,out|
			head["Content-Type"] = "text/plain"
			out.write texte
		end
	end

end

