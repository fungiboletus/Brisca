class Carte
	@id = 0
	@nom = ""
	@force = 0
	@pv = 0
	@precision = 0
	@esquive = 0
	@element = 0

	#@precision_combat
	@esquive_combat

	attr_accessor :id, :nom, :force, :pv, :precision, :esquive, :element, :esquive_combat

	def initialize(id)
		@id = id
		@pv = 0
	end

	def getJson
		json = {
			"id"		=> @id,
			"nom"		=> @nom,
			"force"		=> @force,
			"pv"		=> @pv,
			"estMorte"	=> estMorte,
			"precision"	=> @precision,
			"esquive"	=> @esquive,
			"element"	=> @element
		}

		return json
	end

	def estMorte
		return true if (@pv <= 0)
		return false
	end

	# C'est là que c'est amusant, on va combatter une autre carte, et c'est super bien	
	def combattre (copine)
		LOG.info "Combat entre les cartes: #{@nom} et #{copine.nom}"

		@force = @force.to_i
		@pv = @pv.to_i
		@precision = @precision.to_i
		@esquive = @esquive.to_i

		copine.force = copine.force.to_i
		copine.pv = copine.pv.to_i
		copine.precision = copine.precision.to_i
		copine.esquive = copine.esquive.to_i
		
		@esquive_combat = @esquive
		copine.esquive_combat = copine.esquive

		# On va raconter le combat à la fin, car c'est amusant
		historique = []

		# Mise en place du coup fatal, c'est rigolo et amusant
		if 0==rand(42)	# Une chance sur 42
			historique.push({"coup_fatal"	=> true})
			copine.pv = 0
			@pv = @pv -1
			return historique
		end

		# Deuxième étape, savoir quelle carte commence
		# Après, c'est chacun son tour

		# Pour cela, on va commencer à prendre un nombre aléatoire, mais pour rajouter un peu de suspence, (et pour s'amuser), on ajoute à ce nombre des informations sur les cartes
		alea = rand 100

		historique.push({"attaquant_commence_alea" => (alea < 50)})

		alea = alea + @precision + @esquive + copine.precision + copine.esquive
		alea = alea % 100
		
		tour = alea < 50

		historique.push({"attaquant_commence" => tour})

		while !(estMorte || copine.estMorte)
			
			message = {}		

			if tour
				attaquant	= self
				attaquee	= copine
				tour		= false
				message["attaquant"] = true
			else
				attaquant	= copine
				attaquee	= self
				tour		= true
				message["attaquant"] = false
			end

			chance = attaquee.esquive_combat - attaquant.precision

			if chance <= rand(42)
				pv_attaque	= (attaquant.force*rand).to_i

				attaquee.pv -= pv_attaque

				message["pv_attaque"] = pv_attaque
			else
				message["esquive"] = true
			end
		
			historique.push message

			# À chaque étape, l'esquive baisse
			attaquee.esquive_combat = attaquee.esquive_combat * 2 / 3

			# Partir en boucle infine, ce n'est pas une bonne chose
			attaquant.pv -= 1
			attaquee.pv -= 1

		end

		historique.push({"attaquee_est_morte" => true}) if copine.estMorte
		historique.push({"attaquant_est_morte" => true}) if estMorte

		return historique
		
	end

	def attaquer(copine)
		message = {}

		if !(estMorte || copine.estMorte)

			chance = copine.esquive - @precision

			if chance <= rand(42)
				force = @force

				copine.pv -= @force

				if copine.pv < 0
					force += copine.pv
					
					copine.pv = 0
				end

				message["pv_attaque"] = force
			else
				message["esquive"] = true
			end
		
		end

		return message

	end
end
