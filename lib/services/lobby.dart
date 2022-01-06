import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/services/utils.dart';
import 'package:rxdart/rxdart.dart';

import 'models.dart';

class LobbyBloc {
  final String id;
  final User user;
  late DatabaseReference _lobbyRef;
  late DatabaseReference _playersRef;
  late DatabaseReference _lobbyInfoRef;
  late DatabaseReference _gameRef;
  late DatabaseReference _wordsRef;

  StreamSubscription<DatabaseEvent>? _lobbyInfoSubscription;
  StreamSubscription<DatabaseEvent>? _playersSubscription;
  StreamSubscription<DatabaseEvent>? _gameSubscription;
  StreamSubscription<DatabaseEvent>? _wordsSubscription;

  final loading = BehaviorSubject<bool>.seeded(true);

  // LOBBY STATE

  final host = BehaviorSubject<Player>.seeded(Player.stub());
  final userRole = BehaviorSubject<PlayerRole>.seeded(PlayerRole.spectator);
  final locked = BehaviorSubject<bool>.seeded(false);
  final online = BehaviorSubject<int>.seeded(0);

  final spectators = BehaviorSubject<List<Player>>.seeded(List.empty());
  final redMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final redPlayers = BehaviorSubject<List<Player>>.seeded(List.empty());
  final blueMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final bluePlayers = BehaviorSubject<List<Player>>.seeded(List.empty());

  // GAME STATE

  final state = BehaviorSubject<GameState>.seeded(GameState.preparing);
  final clue = BehaviorSubject<Clue?>.seeded(null);
  final words = BehaviorSubject<List<Word>>.seeded([]);

  final redScore = BehaviorSubject<int>.seeded(0);
  final blueScore = BehaviorSubject<int>.seeded(0);

  LobbyBloc({required this.id, required this.user}) {
    // TODO subscribe on all streams

    // TODO @learn WriteBatch batch = FirebaseFirestore.instance.batch();
    print('LobbyBloc constructor');

    // state.listen((value) {
    //   print('state ' + value.toString());
    // });

    _lobbyRef = FirebaseDatabase.instance.ref("${Lobby.lobbiesKey}/$id");
    _lobbyInfoRef = _lobbyRef.child(Lobby.infoKey);
    _playersRef = _lobbyRef.child(Lobby.playersKey);
    _gameRef = _lobbyRef.child(Lobby.gameKey);
    _wordsRef = _lobbyRef.child(Lobby.wordsKey);

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
          Player(id: user.id, name: user.name, current: true, online: true, host: false, role: PlayerRole.spectator)
              .toJson());
    }

    // 2. subscribe Lobby on db changes

    _lobbyInfoSubscription = _lobbyInfoRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        return;
        // Navigator.pushNamed(context, '/');  // TODO handle lobby deletion
      }

      var lobby = LobbyInfo.fromJson(event.snapshot.value as Map<String, dynamic>, user);
      locked.add(lobby.locked);
    });

    _playersSubscription = _playersRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        return;
      }

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

      online.add(players.where((element) => element.online).length);
    });

    // 2. subscribe Game on db changes

    _gameSubscription = _gameRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        return;
      }

      var lobby = Game.fromJson(event.snapshot.value as Map<String, dynamic>);
      state.add(lobby.state);
      clue.add(lobby.clue);
    });

    _wordsSubscription = _wordsRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        return;
      }

      var words = event.snapshot.children.map((e) => Word.fromJson(e.value as dynamic, e.key!)).toList();
      this.words.add(words);

      var redAll = words.where((element) => element.color == WordColor.red).length;
      var redRevealed = words.where((element) => element.revealed && (element.color == WordColor.red)).length;
      redScore.add(redAll - redRevealed);

      var blueAll = words.where((element) => element.color == WordColor.blue).length;
      var blueRevealed = words.where((element) => element.revealed && (element.color == WordColor.blue)).length;
      blueScore.add(blueAll - blueRevealed);
    });
  }

  resetGame() async {
    await _gameRef.update(Game(clue: null, state: GameState.blueMastersTurn).toJson());
    // TODO reset words
  }

  unlockTeams() async {
    await _lobbyInfoRef.update({LobbyInfo.lockedKey: false});
  }

  lockTeams() async {
    await _lobbyInfoRef.update({LobbyInfo.lockedKey: true});
  }

  becomeSpectator() async {
    await _playersRef.child(user.id).update({Player.roleKey: PlayerRole.spectator.toString()});
  }

  becomeRedPlayer() async {
    await _playersRef.child(user.id).update({Player.roleKey: PlayerRole.redPlayer.toString()});
  }

  becomeRedMaster() async {
    await _playersRef.child(user.id).update({Player.roleKey: PlayerRole.redMaster.toString()});
  }

  becomeBluePlayer() async {
    await _playersRef.child(user.id).update({Player.roleKey: PlayerRole.bluePlayer.toString()});
  }

  becomeBlueMaster() async {
    await _playersRef.child(user.id).update({Player.roleKey: PlayerRole.blueMaster.toString()});
  }

  renameUser(String value) async {
    await _playersRef.child(user.id).update({Player.nameKey: value});
  }

  endPlayerTurn() async {
    if (state.valueOrNull == GameState.redPlayersTurn) {
      await _gameRef.update({Game.clueKey: null, Game.stateKey: GameState.blueMastersTurn.toString()});
    } else if (state.valueOrNull == GameState.bluePlayersTurn) {
      await _gameRef.update({Game.clueKey: null, Game.stateKey: GameState.redMastersTurn.toString()});
    }
  }

  sendClue(Clue clue) async {
    if (state.valueOrNull == GameState.redMastersTurn) {
      await _gameRef.update({Game.clueKey: clue.toJson(), Game.stateKey: GameState.redPlayersTurn.toString()});
    } else if (state.valueOrNull == GameState.blueMastersTurn) {
      await _gameRef.update({Game.clueKey: clue.toJson(), Game.stateKey: GameState.bluePlayersTurn.toString()});
    }
  }

  revealWord(Word word) async {
    // TODO cover in transaction

    var redLeft = redScore.valueOrNull!;
    var blueLeft = blueScore.valueOrNull!;

    await _wordsRef.child(word.id).update({Word.revealedKey: true});

    // black word = lose
    if (word.color == WordColor.black) {
      var whoWon = userRole.valueOrNull!.isRed ? GameState.blueWon : GameState.redWon;
      await _gameRef.update({Game.stateKey: whoWon.toString()});
      return;
    }

    // last colored word = win/lose
    if ((word.color == WordColor.red) && (redLeft == 1)) {
      await _gameRef.update({Game.stateKey: GameState.redWon.toString()});
      return;
    } else if ((word.color == WordColor.blue) && (blueLeft == 1)) {
      await _gameRef.update({Game.stateKey: GameState.blueWon.toString()});
      return;
    }

    // increment revealed count
    var clue = this.clue.valueOrNull!;
    await _gameRef.child(Game.clueKey).update({Clue.openedCountKey: clue.openedCount + 1});

    // end turn if no tries left
    if (clue.openedCount >= clue.count) {
      await endPlayerTurn();
    }
  }

  leave() {
    // TODO delete lobby if no more users
    // TODO Make another user host
    // TODO Delete player
  }

  dispose() {
    // TODO invoke in right place

    print('LobbyBloc dispose');

    _lobbyInfoSubscription?.cancel();
    _playersSubscription?.cancel();
    _gameSubscription?.cancel();
    _wordsSubscription?.cancel();
  }
}
