import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/services/utils.dart';
import 'package:rxdart/rxdart.dart';

import 'models.dart';

enum GameState { preparing, redTurn, blueTurn, end }

class LobbyBloc {
  final String id;
  final User user;
  late DatabaseReference _lobbyRef;
  late DatabaseReference _playersRef;
  late DatabaseReference _lobbyInfoRef;

  StreamSubscription<DatabaseEvent>? _lobbyInfoSubscription;
  StreamSubscription<DatabaseEvent>? _playersSubscription;

  final loading = BehaviorSubject<bool>.seeded(true);

  final host = BehaviorSubject<Player>.seeded(Player.stub());
  final userRole = BehaviorSubject<PlayerRole>.seeded(PlayerRole.spectator);
  final locked = BehaviorSubject<bool>.seeded(false);
  final online = BehaviorSubject<int>.seeded(0);

  // final state = BehaviorSubject<GameState>.seeded(GameState.preparing);

  final spectators = BehaviorSubject<List<Player>>.seeded(List.empty());

  final redMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final redPlayers = BehaviorSubject<List<Player>>.seeded(List.empty());

  final blueMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final bluePlayers = BehaviorSubject<List<Player>>.seeded(List.empty());


  LobbyBloc({required this.id, required this.user}) {
    // TODO subscribe on all streams

    // TODO @learn WriteBatch batch = FirebaseFirestore.instance.batch();
    print('LobbyBloc constructor');

    // state.listen((value) {
    //   print('state ' + value.toString());
    // });

    _lobbyRef = FirebaseDatabase.instance.ref("${Lobby.lobbiesKey}/$id");
    _lobbyInfoRef = _lobbyRef.child(Lobby.infoKey);
    _playersRef = _lobbyRef.child(Player.playersKey);

    _playersRef.child(user.id).onDisconnect().update({Player.onlineKey: false});

    loginAsync().then((value) {
      // let UI show lobby
      loading.add(false);
    });
  }

  loginAsync() async {
    var userPlayer = await _playersRef.child(user.id).get();

    // 1. add user
    if (userPlayer.exists) {
      // set online status to user
      await _playersRef.child(user.id).update({Player.onlineKey: true});
    } else {
      // add user to spectators if nothing
      await _playersRef.child(user.id).set(
          Player(id: user.id,
              name: user.name,
              current: true,
              online: true,
              host: false,
              role: PlayerRole.spectator)
              .toJson());
    }

    // 2. subscribe on db changes

    _lobbyInfoSubscription = _lobbyInfoRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        return;
        // Navigator.pushNamed(context, '/');  // TODO handle lobby deletion
      }

      var lobby = LobbyInfo.fromJson(event.snapshot.value as Map<String, dynamic>, user);
      locked.add(lobby.locked);
    });

    _playersSubscription = _playersRef.onValue.listen((event) {
      var players = event.snapshot.children.map((e) => Player.fromJson(e.value as dynamic, user)).toList();

      var currentPlayer = players.firstWhereOrNull((element) => element.id == user.id);
      if (currentPlayer != null) {
        userRole.add(currentPlayer.role);
      }

      var hostPlayer = players.firstWhereOrNull((element) => element.host);
      if (hostPlayer != null) {
        host.add(hostPlayer);
      }

      spectators.add(players.where((element) => element.role == PlayerRole.spectator).toList());
      redPlayers.add(players.where((element) => element.role == PlayerRole.redPlayer).toList());
      redMasters.add(players.where((element) => element.role == PlayerRole.redMaster).toList());
      bluePlayers.add(players.where((element) => element.role == PlayerRole.bluePlayer).toList());
      blueMasters.add(players.where((element) => element.role == PlayerRole.blueMaster).toList());

      online.add(players
          .where((element) => element.online)
          .length);
    });
  }

  resetGame() {
    // TODO
  }

  unlockTeams() {
    _lobbyInfoRef.set({LobbyInfo.lockedKey: false});
  }

  lockTeams() {
    _lobbyInfoRef.set({LobbyInfo.lockedKey: true});
  }

  becomeSpectator() {
    _playersRef.child(user.id).update({Player.roleKey: PlayerRole.spectator.toString()});
  }

  dispose() {
    // TODO invoke in right place

    print('LobbyBloc dispose');

    _lobbyInfoSubscription?.cancel();
    _playersSubscription?.cancel();

    // set user status to offline
    try {
      _playersRef.child(user.id).update({Player.onlineKey: false});
    } catch (ex) {
      // DO nothing
    }
  }

  _becomeOffline() {
    _playersRef.child(user.id).update({Player.onlineKey: false});
  }

  becomeRedPlayer() {
    _playersRef.child(user.id).update({Player.roleKey: PlayerRole.redPlayer.toString()});
  }

  becomeRedMaster() {
    _playersRef.child(user.id).update({Player.roleKey: PlayerRole.redMaster.toString()});
  }

  becomeBluePlayer() {
    _playersRef.child(user.id).update({Player.roleKey: PlayerRole.bluePlayer.toString()});
  }

  becomeBlueMaster() {
    _playersRef.child(user.id).update({Player.roleKey: PlayerRole.blueMaster.toString()});
  }

  leave() {
    // TODO delete lobby if no more users
    // TODO Make another user host
    // TODO Delete player
  }

  renameUser(String value) {
    _playersRef.child(user.id).update({Player.nameKey: value});
  }
}
