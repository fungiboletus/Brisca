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

	@partie = nil
	@pile = []

	attr_accessor :pile, :partie, :carte_slot
	attr_reader :cartes, :nom, :element, :id, :session, :niveau, :invalide

	def initialize(session)

		@session = session

		LOG.info "Récupération des informations du joueur de la session #{session}"

		$ami_php = PHPFriend.new if !$ami_php
		connexion = $ami_php.connecte session

		if !connexion
			@invalide = true
			return
		end

		@invalide = false
		
		@id = connexion["id"] 
		@nom = connexion["nom"]
		@niveau = connexion["niveau"]
		@element = connexion["element"]

		@pile = []

		#liste_elements = ["eau", "eclair", "feu", "feuille", "metal", "neige", "pierre", "vent"]

	 	#@element = liste_elements.at rand liste_elements.length
	end

	def chargerCartes
		
		@cartes = []
		
		cartes = $ami_php.getCartes self

		cartes.each do |carte|
			obj_carte = Carte.new carte["id"]
			obj_carte.nom	= carte["nom"]
			obj_carte.pv	= carte["pv"]
			obj_carte.force	= carte["force"]
			obj_carte.precision	= carte["precision"]
			obj_carte.esquive	= carte["esquive"]
			obj_carte.element	= carte["element"]

			@cartes.push obj_carte
		end

		#@tirages = []

		#while @cartes.length != 8 do
			#tirage = (rand 128)+1

			#if !@tirages.include? tirage
				#@cartes.push(Carte.new(tirage))
				#@tirages.push tirage
			#end
		#end

		#puts JSON.pretty_generate getCartes
		
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
