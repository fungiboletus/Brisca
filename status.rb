# La liste des status est séparée car c'est plus propre, enfin je pense

class Status
	
# La partie n'est pas valide ou n'existe pas
invalide = 0

# un organisateur a crée la partie, et est en attente d'un joueur
attente_organisateur = 1

# Un candidat se présente à l'organisateur
presentation_candidat = 2

# Les deux joueurs doivent choisir leur cartes
choix_cartes = 3

# L'organisateur peut jouer
attente_organisateur = 4

# L'adversaire peut jouer
attente_adversaire = 5

# Égalité
egalite = 6

# L'organisateur gagne la partie
organisateur_gagnant = 7

# L'adversaire gagne la partie
adversaire_gagnant = 8

end


