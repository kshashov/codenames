import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';

class LobbyCoordinator with ChangeNotifier, DiagnosticableTreeMixin {
  Future<bool> hasLobby(String id) async {
    var doc = await FirebaseDatabase.instance.ref("${Lobby.lobbiesKey}/$id").get();
    return doc.exists;
  }

  Future<String> registerLobby(User user) async {
    // WriteBatch batch = FirebaseDatabase.instance.batch();

    var lobbyRef = FirebaseDatabase.instance.ref(Lobby.lobbiesKey).push();
    await lobbyRef.set({
      Lobby.infoKey: {LobbyInfo.lockedKey: false}
    });

    await lobbyRef.child("${Player.playersKey}/${user.id}").set(Player(
          id: user.id,
          name: user.name,
          host: true,
          current: true,
          online: false,
          role: PlayerRole.spectator,
        ).toJson());
    // batch.set(playerRef, Player(id: user.id, name: user.name, host: true, current: true, online: false, role: PlayerRole.spectator).toJson());

    // await batch.commit();

    return lobbyRef.key!;
  }
}
