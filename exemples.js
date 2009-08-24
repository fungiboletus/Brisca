// Liste des parties:
[
	{ /* Informations partie */ }
	/* … */
]

// Le joueur se connecte sans partie de lancée
{
	"status": 0,
	"liste_parties": [ {}, {}]
}

// Le joueur organise une partie
{
"id_partie": 7,
"nom_partie": "La partie des gens très forts lol",

"status": 1 // attente organisateur
}

// Un joueur se présente comme adversaire à une partie
{
//niania

"status": 2

"adversaire" :{
	"id_adversaire": 12,
		"niveau": 50,
		"element": 28,
		"nom": "Je suis le plus fort, et c'est vrai lol,
	}
}

// Le joueur est en attente de la décision de l'organisateur

{
// niania
	
"status": 3
}

// Et maintenant la partie classique de tout le temps
{
//niania

"status": 4

"changer_carte": true,

"joueur_slot": {}, // Carte

"adversaire_slot": {}, // Carte

"mes_cartes": [
{},
// …

],

"cartes_connus_adversaire": [
{},
// …

]

}

// Et une victoire, classique
{
// niania

"status": 6
}
