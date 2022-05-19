import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

class LobbyCoordinator with ChangeNotifier, DiagnosticableTreeMixin {
  List<String>? _stringWords;

  Future<bool> hasLobby(String id) async {
    var doc = await FirebaseDatabase.instance.ref("${Lobby.lobbiesKey}/$id").get();
    return doc.exists;
  }

  Future<String> registerLobby(User user) async {
    var lobbyRef = FirebaseDatabase.instance.ref(Lobby.lobbiesKey).push();
    await lobbyRef.set({
      Lobby.infoKey: {LobbyInfo.lockedKey: false},
      Lobby.gameKey: {Game.stateKey: GameState.preparing.toString(), Game.clueKey: null, Game.dictionaryKey: ''},
      Lobby.wordsKey: [],
      Lobby.logKey: []
    });

    await lobbyRef.child("${Lobby.playersKey}/${user.id}").set(Player(
      id: user.id,
      name: user.name,
      host: true,
      current: true,
      online: false,
      role: PlayerRole.spectator,
    ).toJson());

    return lobbyRef.key!;
  }
}
