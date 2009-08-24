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
	attr_accessor :date_adversaire

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

		# Savoir quand la partie a commencée
		@date_debut = Time.now

		# Dernier passage de l'adversaire sur la partie
		@date_adversaire = Time.now
		
		# C'est bien de charger les cartes de temps en temps
		@organisateur.chargerCartes

	end

	def nouveauJoueur(joueur)
		return false if (!@joueur_b.nil? || !@joueur_b_temp.nil?)

		@joueur_b_temp = joueur
		joueur.partie = self
		
		@organisateur.message = {
			"nouvel_adversaire" => {
				"nom" => joueur.nom,
				"id" => joueur.id,
				"niveau" => joueur.niveau,
				"element" => joueur.element
			}
		}
		
		return true
	end

	def confirmerJoueur

		# C'est bon, le joueur est le joueur principal :-)
		@joueur_b = @joueur_b_temp

		# Choix de qui commence
		@tour_joueur = rand 2

		# Chargement des cartes du joueur
		@joueur_b.chargerCartes	

	end

	def annulerJoueur
		@refus.push @joueur_b_temp.id

		@joueur_b_temp.partie = nil
		@joueur_b_temp = nil
		
		@joueur_b = nil
		
	end

	def dansLaListe
		return false if @termine 

		return false if @joueur_b 

		# Partie trop vielle si elle date de plus de 60 secondes (c'est rapide, mais c'est fait exprès)
		if @date_adversaire + 60 < Time.now
			
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

		return false if !joueurs # Inutile de tenter de tricher

		# Récupération de la carte qu'il faut changer
		carte = joueurs[0].getCarteById id_carte

		# Si la carte n'existe pas, c'est pas glop
		if !carte
			LOG.warn "Changement de carte avec une carte inconnue: #{id_carte}"
			
			return false 
		end

		# On ne veut pas que l'on puisse changer avec la même carte que précédement…
		return false if carte == joueurs[0].carte_slot

		LOG.info "Chargement de la carte #{carte.id_carte}"

		joueurs[0].carte_slot = carte
		
		# Si le joueur n'a pas de carte ou que sa carte est morte,
		# cela ne lui fait pas changer de tour
		if joueurs[0].carte_slot && !joueurs[0].carte_slot.estMorte
			changerTour
		end

	end

	def attaquer(joueur)

		joueurs = verifierTour(joueur)

		# Vérifications d'usage
		return if !joueurs # Retour si la personne veut tricher

		return if !joueurs[0].carte_slot || !joueurs[1].carte_slot # Retour si un joueur n'a pas de carte dans son slot (pour éviter les bugs)

		return if joueurs[0].carte_slot.estMorte # Retour si la carte du slot est morte

		# Attaquons !
		joueurs[0].carte_slot.attaquer joueurs[1].carte_slot

		# Là, on change de tour à tout les coups
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


	# Ce n'est pas une bonne idée de tricher, sert aussi à récupérer 
	def verifierTour(joueur)
		return [@organisateur, @joueur_b] if @tour_joueur == 0 && joueur == @organisateur

		return  [@joueur_b, @organisateur] if @tour_joueur == 1 && joueur == @joueur_b

		return false
	end

	def donnerGagnant(joueur_gagnant)

		if joueur_gagnant == @organisateur
			@tour_joueur = 2
			$ami_php.finPartie(@organisateur, @joueur_b)
		else
			@tour_joueur = 3
		end

		@termine = true
		
	end

	def abandonner(joueur)
		
	end

	def verifierCartes(joueur)
		joueur.cartes.each do |carte|
			return false if !carte.estMorte
		end

		return true
	end

	def verifierDateReponses
		now = Time.now

		if @organisateur.date_reponse + 180 < now || @joueur_b.date_reponse + 180 < now
			if @organisateur.date_reponse > @joueur_b.date_reponse
				donnerGagnant @organisateur
			else
				donnerGagnant @joueur_b
			end
		end
	end

	def informationsPartie(joueur)
		verifierFinPartie

		informations = {
			:mes_cartes	=> 
		}
	end

end
