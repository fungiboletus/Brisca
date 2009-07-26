require "net/http"
require "uri"
require "timeout"
require "digest"
require "json"

class PHPFriend
	
	def initialize

		@user_agent = "PoneyServeur"
		@referer	= "http://perdu.com/"
		@timeout	= 2
		
		@url_connexion	= "http://www.elementz.fr/jeu/connecte.php"
		@url_cartes		= "http://www.elementz.fr/jeu/deck.php"
		@url_fin_partie	= "http://www.elementz.fr/jeu/fin_partie.php"

		@nom_param_session = "?PHPSESSID="
		
#@nom_param_session = ""
#@url_connexion	= "http://localhost/lol2/"
#@url_cartes		= "http://localhost/lol2/"
#@url_fin_partie	= "http://localhost/lol2/"
	end

	def load_url(url)
		LOG.info "Chargement de l'url: #{url}"

		# Parsage de l'url
		uri = URI.parse(url)

		code = nil
		data = nil

		begin

			Timeout::timeout(@timeout) do
				http = Net::HTTP.new(uri.host, uri.port)

				salut = uri.path
				salut = "#{salut}?#{uri.query}" if uri.query				

				code, data = http.get(salut, {
					"User-Agent"	=> @user_agent,
					"Referer"		=> @referer
				})

				if code.code != "200"
					LOG.warn "Erreur lors du chargement de l'url, code de retour: #{code.code}"
				end

			end

		rescue Timeout::Error
			LOG.error "Timeout lors du chargement de l'url"
			return false

		rescue
			LOG.error "Erreur sérieuse lors du chargement de l'url"
			return false
		end

		return data
	end

	def connecte(session)
		code = load_url(@url_connexion + @nom_param_session+session)

		json = JSON.parse code
		LOG.debug json

		return json
	end

	def getCartes(joueur)
		code = load_url(@url_cartes + @nom_param_session+joueur.session)
		
		json = JSON.parse code
		LOG.debug json

		return json
	end

	def finPartie(gagnant, perdant)
#load_url(@url_fin_partie + @nom_param_session+gagnant.session+'?gagne=true')
#load_url(@url_fin_partie + @nom_param_session+perdant.session+'?gagne=false')
	end
end
