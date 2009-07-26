require 'Joueur.rb'

class	Partie 

	@organisateur = nil

	@joueur_b = nil
	@joueur_b_temp = nil
	
	@pile_a = []
	@pile_b = []

	@nom = ""
	@mdp = ""

	@refus = []

	@termine = false

	@date_debut = 0

	@id = 0

	@tour_joueur = nil

	attr_reader :id, :nom, :mdp, :organisateur, :joueur_b, :joueur_b_temp, :refus

	def initialize(id, nom, mot_de_passe, organisateur)
		
		LOG.info "Création de la partie #{id}"	

		@id = id
			
		@organisateur = organisateur

		# Protection contre les méchants pas beaux
		@nom = nom.slice(0,250).gsub('&','&amp;').gsub('<','&lt;').gsub('>','&gt;')
		@mdp = mot_de_passe

		organisateur.partie = self
		
		@pile_a = []
		@pile_b = []

		@refus = [] 
	
		@termine = false

		@date_debut = 0

		organisateur.pile = @pile_a

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

		@pile_a.push infos 
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
		
		@pile_a.push  commande

		@pile_b = [
			{
				"connexion_partie" => true
			}
		]

		joueur.pile = @pile_b

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
			@pile_a.push commence_t
			@pile_b.push commence_f
		else
			# L'adversaire commence
			@pile_a.push commence_f
			@pile_b.push commence_t
		end

		@joueur_b.chargerCartes	

		cartes = {
			"mes_cartes" => @joueur_b.getCartes
		}

		@pile_b.push cartes

		j_a = @organisateur.getJson
		j_b = @joueur_b.getJson

		@pile_a.push({"nous" => j_a, "adversaire" => j_b})
		@pile_b.push({"nous" => j_b, "adversaire" => j_a})
	end

	def annulerjoueur
		@refus.push @joueur_b_temp.id

		@joueur_b_temp.partie = nil
		@joueur_b_temp = nil
		
		@joueur_b = nil
		
		@pile_b.clear
	end

	def danslaliste
		return false if @termine 

		return false if @joueur_b 

		# Partie trop vielle if @date < ahah

		return true
	end

	def changerTour
		@tour_joueur = (@tour_joueur + 1) % 2
	end

	def changerCarte(joueur, id_carte)
		joueurs = verifierTour(joueur)

		return false if !joueurs

		carte = joueurs[0].getCarteById id_carte

		return false if !carte

		# On ne veut pas que l'on puisse changer avec la même carte que précédement…
		return false if carte == joueurs[0].carte_slot

		LOG.info "Chargement de la carte #{carte.id}"

		joueurs[0].carte_slot = carte

		message = {
			"changement_carte" => carte.getJson
		}
		
		joueurs[1].pile.push message

		# À la fin, pour éviter de tricher, quand même
		changerTour
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

		#s_orga = true
		#s_b = true

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

end
