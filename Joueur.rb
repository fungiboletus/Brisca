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

	@date_reponse = nil
	@message = false

	attr_accessor :partie, :carte_slot, :message
	attr_reader :cartes, :nom, :element, :id, :session, :niveau, :invalide, :date_reponse

	def initialize(session)

		@session = session

		LOG.info "Récupération des informations du joueur de la session #{session}"

		$ami_php = PHPFriend.new if !$ami_php
		connexion = $ami_php.connecte session

		if connexion["ok"] != nil && !connexion["ok"]
			@invalide = true
			return
		end

		@invalide = false
		
		@id = connexion["id"] 
		@nom = connexion["nom"]
		@niveau = connexion["niveau"]
		@element = connexion["element"]

		@message = false

	end

	def	getJson
		json = {
			"id"		=> @id,
			"nom"		=> @nom,
			"niveau"	=> @niveau,
			"element"	=> @element
		}

		return json
	end

	def chargerCartes
		
		@cartes = []
		
		cartes = $ami_php.getCartes self
		
		i = 0	

		cartes.each do |carte|
			obj_carte			= Carte.new carte["id"]
			obj_carte.id_carte	= i
			obj_carte.nom		= carte["nom"]
			obj_carte.pv		= carte["pv"]
			obj_carte.force		= carte["force"]
			obj_carte.precision	= carte["precision"]
			obj_carte.esquive	= carte["esquive"]
			obj_carte.element	= carte["element"]

			@cartes.push obj_carte

			++i
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
			if carte.id_partie == id_carte
				return carte
			end
		end

		return false
	end
	
	def nadalol
	end

	def enVie
		@date_reponse = Time.now
	end

	def attaquer
		@partie.attaquer self
	end

	def changerCarte(id_carte)
		@partie.changerCarte(self,id_carte)
	end

	def informationsPartie
		@partie.informationsPartie self
	end
end
