require 'Joueur.rb'

class	Partie 

	# L'organisateur de la partie
	@organisateur = nil

	# L'adversaire, le joueur temporaire sert à la connexion
	@joueur_b = nil
	@joueur_b_temp = nil

	# Nom de la partie, et mot de passe si besoin
	@nom = ""
	@mdp = ""

	# La liste des adversaires refusés, pour pas qu'ils puissent refaire une demande
	@refus = []

	# Pour savoir si la partie est terminée
	@termine = false

	# Date de début de la partie
	@date_debut = 0
	
	# Nombre de tours, pour se tenir au courant de l'avancement quand même
	@nombre_tours = 0

	# Identifiant de la partie
	@id = 0

	# Tour de joueur
	@tour_joueur = nil

	attr_reader :id, :nom, :mdp, :organisateur, :joueur_b, :joueur_b_temp, :refus, :nombre_tours

	def initialize(id, nom, mot_de_passe, organisateur)
		
		LOG.info "Création de la partie #{id}"	

		@id = id
	
		@nombre_tours = 0
			
		@organisateur = organisateur

		# Protection contre les méchants pas beaux
		@nom = nom.slice(0,250).gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;')
		@mdp = mot_de_passe

		organisateur.partie = self
		
		@refus = [] 
	
		@termine = false

		@date_debut = Time.now
		@date_adversaire = Time.now
		@date_joueur_b = 0

		organisateur.chargerCartes

		informerOrganisateur

	end

	def informerOrganisateur
		
		infos = {
				"type"		=> "organisation_partie",
				"mes_cartes"	=> organisateur.getCartes,
				"id_partie"	=> id,
				"element"	=> organisateur.element,
				"adversaire"	=> false
		}

		if @joueur_b
			infos["adversaire"] = true
		end

		@organisateur.pile.push infos 
	end

	def nouveauJoueur(joueur)
		return false if (!@joueur_b.nil? || !@joueur_b_temp.nil?)

		@joueur_b_temp = joueur
		joueur.partie = self
		
		commande = {
			"nouvel_adversaire" => {
				"nom" => joueur.nom,
				"id" => joueur.id,
				"niveau" => joueur.niveau,
				"element" => joueur.element
			}
		}
		
		@organisateur.pile.push  commande

		@joueur_b_temp.pile = [
			{
				"connexion_partie" => "reussie"
			}
		]

		return true
	end

	def confirmerJoueur
		@joueur_b = @joueur_b_temp

		message = {
			"element_partie"		=> @organisateur.element
		}

		@joueur_b.pile.push message
		
		message = {
			"decision_organisateur" => true,
		}

		@joueur_b.pile.push message

		commence_t = {
			"on_commence" => true
		}
		
		commence_f = {
			"on_commence" => false 
		}

		@tour_joueur = rand 2
		
		# qui commence ?
		if (@tour_joueur == 0)
			# L'organisateur commence
			@organisateur.pile.push commence_t
			@joueur_b.pile.push commence_f
		else
			# L'adversaire commence
			@organisateur.pile.push commence_f
			@joueur_b.pile.push commence_t
		end

		@joueur_b.chargerCartes	

		cartes = {
			"mes_cartes" => @joueur_b.getCartes
		}

		@joueur_b.pile.push cartes

		j_a = @organisateur.getJson
		j_b = @joueur_b.getJson

		@organisateur.pile.push({"nous" => j_a, "adversaire" => j_b})
		@joueur_b.pile.push({"nous" => j_b, "adversaire" => j_a})
	end

	def annulerjoueur
		@refus.push @joueur_b_temp.id

		@joueur_b_temp.partie = nil
		@joueur_b_temp = nil
		
		@joueur_b = nil
		
		@joueur_b.pile.clear
	end

	def danslaliste
		return false if @termine 

		return false if @joueur_b 

		# Partie trop vielle si elle date de plus de 30 secondes (c'est rapide, mais c'est fait exprès)
		if @date_adversaire + 3600 < Time.now
			
			finPartie
			return false
		
		end
		return true
	end

	def changerTour
		@tour_joueur = (@tour_joueur + 1) % 2
		@nombre_tour += 1
	end

	def changerCarte(joueur, id_carte)
		joueurs = verifierTour(joueur)

		return false if !joueurs

		carte = joueurs[0].getCarteById id_carte

		return false if !carte

		# Si le joueur n'a pas de carte ou que sa carte est morte,
		# cela ne lui fait pas changer de tour
		changement_tour = true

		if !joueurs[0].carte_slot || joueurs[0].carte_slot.estMorte
			changement_tour = false
		end

		# On ne veut pas que l'on puisse changer avec la même carte que précédement…
		return false if carte == joueurs[0].carte_slot

		LOG.info "Chargement de la carte #{carte.id}"

		joueurs[0].carte_slot = carte

		json_carte = carte.getJson
		json_carte["changement_tour"] = changement_tour

		message = {
			"changement_carte" => json_carte
		}
		
		if @nombre_tours != 0
			joueurs[1].pile.push message
		else
			joueurs[1].message_debut_partie = message
		end

		# Il ne faut pas oublier de changer de tour
		changerTour if changement_tour
	end

	def attaquer(joueur)

		joueurs = verifierTour(joueur)

		return if !joueurs[0].carte_slot || !joueurs[1].carte_slot

		return if joueurs[0].carte_slot.estMorte

		historique = joueurs[0].carte_slot.attaquer joueurs[1].carte_slot

		verifier_fin_partie

		carte_attaquant = joueurs[0].carte_slot.getJson
		carte_attaquant["attaquant"] = true
		carte_attaquant = {"infos_carte" => carte_attaquant}

		@organisateur.pile.push	carte_attaquant
		@joueur_b.pile.push		carte_attaquant

		carte_attaque = joueurs[1].carte_slot.getJson
		carte_attaque["attaquant"] = false
		carte_attaque = {"infos_carte" => carte_attaque}

		@organisateur.pile.push	carte_attaque
		@joueur_b.pile.push		carte_attaque
		
		@organisateur.pile.push({"infos_attaque" => historique})
		@joueur_b.pile.push({"infos_attaque" => historique})

		changerTour
		
	end

	def verifier_fin_partie
		s_orga	= verifier_organisateur
		s_b		= verifier_joueur_b

		# Si il y a égalité
		if s_orga && s_b
			
			message = {"tirage_au_sort" => true}
			@organisateur.pile.push message
			@joueur_b.pile.push message

			if 0==rand(2)
				@organisateur.annoncerVictoire
				@joueur_b.annoncerDefaite
			else
				@organisateur.annoncerDefaite
				@joueur_b.annoncerVictoire
			end

		# Si le joueur b gagne
		elsif s_orga && ! s_b
				@organisateur.annoncerDefaite
				@joueur_b.annoncerVictoire
		# Si l'organisateur gagne
		elsif !s_orga && s_b
				@organisateur.annoncerVictoire
				@joueur_b.annoncerDefaite
		end

		# Si il y en a un des deux qui gagne, c'est la fin de la partie
		if s_orga || s_b
			finPartie
			
			# Notifications des fins de parties
			if s_orga
				$ami_php.finPartie(@organisateur, @joueur_b)
			else
				$ami_php.finPartie(@joueur_b, @organisateur)
			end
				
		end

	end

	def verifier_organisateur
		@organisateur.cartes.each do |carte|
			return false if !carte.estMorte
		end

		return true
	end

	def verifier_joueur_b
		@joueur_b.cartes.each do |carte|
			return false if !carte.estMorte
		end

		return true
	end

	# Ce n'est pas une bonne idée de tricher
	def verifierTour(joueur)
		return [@organisateur, @joueur_b] if @tour_joueur == 0 && joueur == @organisateur

		return  [@joueur_b, @organisateur] if @tour_joueur == 1 && joueur == @joueur_b

		return false
	end

	def finPartie
		@organisateur.partie = nil
		@joueur_b.partie = nil

		@termine = true
	end

	def abandonner(joueur)
		
	end

	def verifierTempsReponse
		
	end

end
