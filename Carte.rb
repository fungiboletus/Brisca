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

	#@precision_combat
	@esquive_combat

	attr_accessor :id, :nom, :force, :pv, :precision, :esquive, :element, :esquive_combat, :carte_vue

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
