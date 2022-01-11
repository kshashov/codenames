# Flutter Codenames [online](https://kshashov.github.io/codenames-web/#/)

[![Demo](https://img.shields.io/badge/Demo-Online-brightgreen)](https://kshashov.github.io/codenames-web/#/)

A simple implementation of [Codenames](https://en.wikipedia.org/wiki/Codenames_(board_game)) board game on [Flutter](https://flutter.dev/) & [Firebase](https://firebase.google.com/).

> The objective of codenames is to correctly guess all of your teams’ code words on the board before the other team does and without guessing the assassin. This is possible because your Spymaster will give you a one-word clue and a number. Using this information and similar clues throughout the game your team will try to interpret the spymaster’s clue and guess each code word.

![Web](/docs/codenames_web.png "Web")

## Implementation details

- Flutter 2.8.1 stable channel
- Firebase real-time database as backend
- Support for Web and Android builds

When a person first logs into the application, he gets an identifier and a default name, which are immediately saved locally. I use shared_preferences library for local storage.

The user can
- Create a new lobby with unique identifier. Lobbies are stored in the Firebase in the following structure:
	```json
	{
	  "game" : {
		"dictionary" : "https://gist.githubusercontent.com/kshashov/71a913d15a2aa662cd83a79cdd2a4635/raw/06f4247317ec75da9d6268b4d0de2dbf4be45765/ru.txt",
		"state" : "GameState.redMastersTurn"
	  },
	  "info" : {
		"locked" : false
	  },
	  "log" : {
		"-Mt2pl4imW03aSo8u_r1" : {
		  "text" : "gives clue",
		  "who" : "NoName",
		  "word" : {
			"color" : "WordColor.blue",
			"text" : "myclue 1"
		  }
		},
	  },
	  "players" : {
		"2ee71670-721c-11ec-bee3-5fa1b7b321f1" : {
		  "host" : true,
		  "id" : "2ee71670-721c-11ec-bee3-5fa1b7b321f1",
		  "name" : "NoName",
		  "online" : false,
		  "role" : "PlayerRole.redPlayer"
		},
	  },
	  "words" : [ {
		  "color" : "WordColor.blue",
		  "text" : "river"
		},
	  ]
	}
	```
- Open an existing one by it's identifier. The user will be added to a lobby as a spectator or just marked as online if he is already in the `players` collection. When user's app becomes disconnected from Firebase, it marks user's player as offline.

From flutter perspective, it is a very simple application with a couple of screens and Bloc architecture. I use `scoped_model` to propagate all services in entire widgets tree. Services expose multiple reactive streams (I use `rxdart` library) that are populated in Firebase listeners. And than widgets consume these streams with `StreamBuilder`s.

There is no unique Web features, so app supports other platforms out of the box. I just created several sets of paddings and font sizes to support different screen resolutions.

![Android2](/docs/codenames_android2.png "Android2")
![Android](/docs/codenames_android.png "Android")
