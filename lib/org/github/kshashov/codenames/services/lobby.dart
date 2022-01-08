import 'dart:async';
import 'dart:math';

import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import 'models.dart';

class LobbyBloc {
  static const enPackUri =
      'https://gist.githubusercontent.com/kshashov/71a913d15a2aa662cd83a79cdd2a4635/raw/06f4247317ec75da9d6268b4d0de2dbf4be45765/en.txt';
  static const ruPackUri =
      'https://gist.githubusercontent.com/kshashov/71a913d15a2aa662cd83a79cdd2a4635/raw/06f4247317ec75da9d6268b4d0de2dbf4be45765/ru.txt';

  final String id;
  final User user;
  late DatabaseReference _lobbyRef;
  late DatabaseReference _playersRef;
  late DatabaseReference _lobbyInfoRef;
  late DatabaseReference _gameRef;
  late DatabaseReference _wordsRef;
  late DatabaseReference _logRef;

  StreamSubscription<DatabaseEvent>? _lobbyInfoSubscription;
  StreamSubscription<DatabaseEvent>? _playersSubscription;
  StreamSubscription<DatabaseEvent>? _gameSubscription;
  StreamSubscription<DatabaseEvent>? _wordsSubscription;
  StreamSubscription<DatabaseEvent>? _logSubscription;

  final loading = BehaviorSubject<bool>.seeded(true);

  // LOBBY STATE

  final host = BehaviorSubject<Player>.seeded(Player.stub());
  final userRole = BehaviorSubject<PlayerRole>.seeded(PlayerRole.spectator);
  final locked = BehaviorSubject<bool>.seeded(false);
  final online = BehaviorSubject<int>.seeded(0);
  final dictionary = BehaviorSubject<String>.seeded('');

  final spectators = BehaviorSubject<List<Player>>.seeded(List.empty());
  final redMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final redPlayers = BehaviorSubject<List<Player>>.seeded(List.empty());
  final blueMasters = BehaviorSubject<List<Player>>.seeded(List.empty());
  final bluePlayers = BehaviorSubject<List<Player>>.seeded(List.empty());

  // GAME STATE

  final state = BehaviorSubject<GameState>.seeded(GameState.preparing);
  final clue = BehaviorSubject<Clue?>.seeded(null);
  final words = BehaviorSubject<List<Word>>.seeded([]);
  final logs = BehaviorSubject<List<LogEntry>>.seeded([]);

  final redScore = BehaviorSubject<int>.seeded(0);
  final blueScore = BehaviorSubject<int>.seeded(0);

  LobbyBloc({required this.id, required this.user}) {
    _lobbyRef = FirebaseDatabase.instance.ref("${Lobby.lobbiesKey}/$id");
    _lobbyInfoRef = _lobbyRef.child(Lobby.infoKey);
    _playersRef = _lobbyRef.child(Lobby.playersKey);
    _gameRef = _lobbyRef.child(Lobby.gameKey);
    _wordsRef = _lobbyRef.child(Lobby.wordsKey);
    _logRef = _lobbyRef.child(Lobby.logKey);

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
        // Navigator.pushNamed(context, '/');  // TODO handle lobby deletion if possible
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
      dictionary.add(lobby.dictionary);
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

    _logSubscription = _logRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        this.logs.add([]);
      }

      var logs = event.snapshot.children.map((e) => LogEntry.fromJson(e.value as dynamic)).toList();
      this.logs.add(logs);
    });
  }

  tryStartGame(String dictionaryLink) async {
    GameState? newState;
    if (dictionaryLink.isNotEmpty) {
      newState = await tryPushNewWords(dictionaryLink);
    }

    if (newState == null) return;
    await _logRef.set({});
    await _gameRef.update(Game(clue: null, state: newState, dictionary: dictionaryLink).toJson());
  }

  Future<GameState> tryPushNewWords(String dictionaryLink) async {
    final stringWords = await tryLoadWords(dictionaryLink);

    List<int> wordTextIndexes = [];
    Random random = Random();
    while (wordTextIndexes.length < 25) {
      int number = random.nextInt(stringWords.length);
      if (!wordTextIndexes.contains(number)) {
        wordTextIndexes.add(number);
      }
    }

    GameState state;
    WordColor color1;
    WordColor color2;
    if (random.nextBool()) {
      state = GameState.redMastersTurn;
      color1 = WordColor.red;
      color2 = WordColor.blue;
    } else {
      state = GameState.blueMastersTurn;
      color1 = WordColor.blue;
      color2 = WordColor.red;
    }

    var wordColors = List.generate(
        25,
            (i) => i < 9
            ? color1
            : (i < 17
            ? color2
                : i < 18
                    ? WordColor.black
                    : WordColor.grey));
    wordColors.shuffle();

    var words = List<dynamic>.generate(25, (i) {
      return Word(id: i.toString(), text: stringWords[wordTextIndexes[i]], color: wordColors[i]).toJson();
    });

    await _wordsRef.set(words);

    await _gameRef.update({Game.dictionaryKey: dictionaryLink});
    return state;
  }

  Future<List<String>> tryLoadWords(String dictionaryLink) async {
    final uri = Uri.parse(dictionaryLink);

    // Await the http get response, then decode the json-formatted response.
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      var body = response.body;
      if (body.isNotEmpty) {
        var stringWords = body.split(';');
        if (stringWords.length < 25) {
          throw ArgumentError('Dictionary size is lower than 25 words');
        }
        return stringWords;
      }
    }
    throw ArgumentError('Dictionary data is unavailable');
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

  makeHost(Player player) async {
    await _playersRef.child(player.id).update({Player.hostKey: true});
    await _playersRef.child(user.id).update({Player.hostKey: false});
  }

  endPlayerTurn() async {
    if (state.valueOrNull == GameState.redPlayersTurn) {
      await _gameRef.update({Game.clueKey: null, Game.stateKey: GameState.blueMastersTurn.toString()});
    } else if (state.valueOrNull == GameState.bluePlayersTurn) {
      await _gameRef.update({Game.clueKey: null, Game.stateKey: GameState.redMastersTurn.toString()});
    }
  }

  sendClue(Clue clue) async {
    var isBlue = state.valueOrNull == GameState.redMastersTurn;
    var isRed = state.valueOrNull == GameState.blueMastersTurn;
    if (isBlue) {
      await _gameRef.update({Game.clueKey: clue.toJson(), Game.stateKey: GameState.redPlayersTurn.toString()});
    } else if (isRed) {
      await _gameRef.update({Game.clueKey: clue.toJson(), Game.stateKey: GameState.bluePlayersTurn.toString()});
    }

    var color = isBlue
        ? WordColor.blue
        : isRed
        ? WordColor.red
        : WordColor.grey;

    await _logRef.push().set(LogEntry(
        who: user.name, text: 'gives clue', word: Word(id: '', text: "${clue.text} ${clue.count}", color: color))
        .toJson());
  }

  revealWord(Word word) async {
    // TODO cover in transaction

    var redLeft = redScore.valueOrNull!;
    var blueLeft = blueScore.valueOrNull!;

    await _logRef.push().set(LogEntry(who: user.name, text: 'taps', word: word).toJson());
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
    print('LobbyBloc dispose');

    _lobbyInfoSubscription?.cancel();
    _playersSubscription?.cancel();
    _gameSubscription?.cancel();
    _wordsSubscription?.cancel();
    _logSubscription?.cancel();
  }
}
