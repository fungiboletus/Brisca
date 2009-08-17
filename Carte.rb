class Carte
	@id = 0
	@id_partie = 0
	@nom = ""
	@force = 0
	@pv = 0
	@precision = 0
	@esquive = 0
	@element = 0
	@carte_vue = false

	attr_accessor :id, :id_partie, :nom, :force, :pv, :precision, :esquive, :element, :carte_vue

	def initialize(id)
		@id = id
		@pv = 0
		@carte_vue = false
	end

	def getJson
		json = {
			"id"		=> @id,
			"id_partie"	=> $id_partie,
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

	def attaquer(copine)

		if !(estMorte || copine.estMorte)

			chance = copine.esquive - @precision

			# Si la carte n'esquive pas
			if chance <= rand(42)
				force = @force

				copine.pv -= @force

				copine.pv = 0 if copine.pv < 0
			end
		
		end

	end
end
