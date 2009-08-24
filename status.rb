# La liste des status est séparée car c'est plus propre, enfin je pense

class Status
	
# La partie n'est pas valide ou n'existe pas
sanspartie = 0

# un organisateur a crée la partie, et est en attente d'un joueur
attente_organisateur = 1

# Un candidat se présente à l'organisateur
presentation_candidat = 2

# Un candidat est en attente de la décision de l'organisateur
attente_candidat = 3

# En jeu 
en_jeu = 4

# Égalité
egalite = 5

# L'organisateur gagne la partie
organisateur_gagnant = 6

# L'adversaire gagne la partie
adversaire_gagnant = 7

end


