require "net/http"
require "uri"
require "timeout"
require "digest"
require "json"

class PHPFriend

	def load_url(url)
		LOG.info "Chargement de l'url: #{url}"

		# Parsage de l'ul
		uri = URI.parse(url)

		code = nil
		data = nil

		begin

			Timeout::timeout(TIMEOUT) do
				http = Net::HTTP.new(uri.host, uri.port)

				salut = uri.path
				salut = "#{salut}?#{uri.query}" if uri.query				

				code, data = http.get(salut, {
					"User-Agent"	=> USER_AGENT,
					"Referer"		=> REFERER_SERVEUR
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
		code = load_url(URL_CONNEXION + NOM_PARAM_SESSION+session)

		json = JSON.parse code
		LOG.debug json

		return json
	end

	def getCartes(joueur)
		code = load_url(URL_CARTES + NOM_PARAM_SESSION+joueur.session)
		
		json = JSON.parse code
		LOG.debug json

		return json
	end

	def finPartie(gagnant, perdant)
		load_url(URL_FIN_PARTIE + NOM_PARAM_SESSION+gagnant.session+'?gagne=true')
		load_url(URL_FIN_PARTIE + NOM_PARAM_SESSION+perdant.session+'?gagne=false')
	end
end
