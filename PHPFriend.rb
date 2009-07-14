require "net/http"
require "uri"
require "timeout"
require "digest"
require "json"

class PHPFriend
	
	def initialize

		@user_agent = "Salutlesamis"
		@referer	= "http://lol.fr/"
		@timeout	= 5
		
		@url_connexion	= "http://salut.lol/connexion.php"
		@url_cartes		= "http://lol.fr/cartes.php"
		@url_fin_partie	= "http://salut.com/fin_partie.php"

		@nom_param_session = "?PHPESSID="
		
		@nom_param_session = ""
		@url_connexion	= "http://localhost/lol2/"
		@url_cartes		= "http://localhost/lol2/"
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

				code, data = http.get(uri.path, {
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
		code = load_url(@url_connexion + @nom_param_session+session+'.txt')

		return false if !code

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

	def finPartie(gagne)
		load_url(@url_fin_partie + @nom_param_session+gagnant.session+'&gagne='+gagne)
	end
end
