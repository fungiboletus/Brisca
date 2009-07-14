require 'Carte.rb'
require 'PHPFriend.rb'

class Joueur
	
	@nom = ""
	@cartes = []
	@carte_slot = nil
	@element = ""
	@niveau = 0
 
	@id = 0
	@session = 28
	@invalide = false
	@ami_php = nil

	@partie = nil
	@pile = []

	attr_accessor :pile, :partie, :carte_slot
	attr_reader :cartes, :nom, :element, :id, :session, :niveau, :invalide

	def initialize(session)

		LOG.info "Récupération des informations du joueur de la session #{session}"

		AMI_PHP = new PHPFriend if !AMI_PHP
		connexion = AMI_PHP.connecte session

		if !connexion
			@invalide = true
			return
		end

		@invalide = false
		
		@id = connexion.id 
		@nom = connexion.nom
		@niveau = connexion.niveau
		@element = connexion.element

		@pile = []

		#liste_elements = ["eau", "eclair", "feu", "feuille", "metal", "neige", "pierre", "vent"]

	 	#@element = liste_elements.at rand liste_elements.length
	end

	def chargerCartes
		@cartes = AMI_PHP.getCartes self

		#@tirages = []

		#while @cartes.length != 8 do
			#tirage = (rand 128)+1

			#if !@tirages.include? tirage
				#@cartes.push(Carte.new(tirage))
				#@tirages.push tirage
			#end
		#end
		
	end

	def getPile
		if @pile
			pile = @pile.clone
			@pile.clear
			return pile
		else
			return []
		end
	end

	def getCartes
		obj = []

		cartes.each do |carte|
			obj.push carte.getJson
		end

		return obj
	end

	def getCarteById(id_carte)
		@cartes.each do |carte|
			if carte.id == id_carte
				return carte
			end
		end

		return false
	end
	
	def nadalol
		@pile.push({"nada" => true})
	end

	def annoncerVictoire
		@pile.push({"victoire" => true})
	end

	def annoncerDefaite
		@pile.push({"defaite" => true})
	end
end
