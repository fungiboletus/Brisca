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
				if partie.dansLaListe	

					obj.push partie.getJSON
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

		# En fonction de ce qu'il faut faire
		case p["action"]
		
		# Si il faut créer une nouvelle partie
		when "nouvelle_partie"
			
			# Si la partie n'existe pas
			if p["nom_partie"] && joueur.partie.nil?
			
				# Création de la partie
				partie = Partie.new $parties.size, p["nom_partie"], p["motdepasse"], joueur				
				
				# Ajout à la liste des parties
				$parties[partie.id] = partie
			end

		# Si un joueur veut se connecter à une partie déjà organisée
		when "connexion_adversaire"
			if !joueur.partie || joueur.partie.termine
			
				partie = $parties[p["id_partie"].to_i]

				if !partie.refus.include? joueur.id
					# Vérification du mot de passe si il y en a un
					if partie.mdp && partie.mdp != ""
						LOG.debug "Protection par mot de passe: #{partie.mdp} vs #{p["motdepasse"]}"	
						if !(partie.mdp == p["motdepasse"] && (partie.nouveauJoueur joueur))
							joueur.message =  {
								"connexion_partie" => "mdp_faux"
							}

						end
					else
						if !(partie.nouveauJoueur joueur)
							joueur.message =  {
								"connexion_partie" => "place_prise"
							}
						end
					end
				else
							joueur.message =  {
								"connexion_partie" => "refus_partie"
							}
				end
			end

		# Pour quand l'organisateur est en attente
		when "attente_adversaire"
			# Il faut faire comprendre que l'organisateur est toujours là
			joueur.partie.date_adversaire = Time.now

		when "attente_organisateur"
			joueur.nadalol
	
		when "attente_action_adversaire"
			joueur.nadalol

		# Quand l'organisateur refuse ou accepte un adversaire
		when "confirmation_adversaire"
			if joueur.partie && joueur.partie.joueur_b_temp
				if p["decision"]
					joueur.partie.confirmerJoueur

					# Il faut réveiller les joueurs
					joueur.partie.organisateur.enVie
					joueur.partie.joueur_b.enVie

					joueur_b.message = {
						"connexion_partie" => "ok"
					}

				else
					
					partie = joueur.partie

					joueur_b = partie.joueur_b_temp

					partie.annulerJoueur

					joueur_b.message = {
						"connexion_partie" => "refus_partie"
					}

				end
			end

		when "changement_carte"
			if joueur.partie && p["id_nouvelle_carte"]
				joueur.changerCarte p["id_nouvelle_carte"]
			end
		
		when "attaquer"
			if joueur.partie
				joueur.attaquer
			end

		when "abandonner"
			if joueur.partie
				joueur.abandonner
			end

		when "fin_partie"
			# Il faut libérer le joueur de la partie
			joueur.partie = nil

		else
			LOG.warn "L'action demandée n'a pas été trouvée"
		end
		
		# Envoi des informations à propos de la partie
		informations = joueur.informationsPartie

		# Si il y a un message à faire passer, qu'il passe
		if joueur.message
			informations["message"] = joueur.message
			joueur.message = false
		end
	
		ecrire JSON.pretty_generate(informations), response

	end

	def ecrire(texte, rq)
		rq.start(200) do |head,out|
			head["Content-Type"] = "text/plain"
			out.write texte
		end
	end

end

