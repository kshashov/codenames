import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:uuid/uuid.dart';

class User {
  static const idKey = 'id';
  static const nameKey = 'name';

  late String id;
  late String name;

  User(this.id, this.name);

  User.fromJson(Map<dynamic, dynamic> userMap) {
    const uuid = Uuid();
    id = userMap[idKey] ?? uuid.v1();
    name = userMap[nameKey] ?? "NoName";
  }

  Map<String, dynamic> toJson() {
    return {
      idKey: id,
      nameKey: name,
    };
  }
}

enum PlayerRole { spectator, bluePlayer, blueMaster, redPlayer, redMaster }

class Player {
  static const idKey = 'id';
  static const nameKey = 'name';
  static const onlineKey = 'online';
  static const hostKey = 'host';
  static const roleKey = 'role';

  late final String id;
  late final String name;
  late final bool online;
  late final PlayerRole role;
  late final bool current; // should not be exposed outside!
  late final bool host; // should only be exposed if true

  Player(
      {required this.id,
      required this.name,
      required this.current,
      required this.online,
      required this.host,
      required this.role});

  get fullName => current ? name + ' (you)' : name;

  Player.stub() {
    id = 'Loading';
    name = 'Loading';
    online = false;
    current = false;
    host = false;
    role = PlayerRole.spectator;
  }

  Player.fromJson(Map<dynamic, dynamic> userMap, User currentUser) {
    id = userMap[idKey];
    name = userMap[nameKey];
    online = userMap[onlineKey];
    current = id == currentUser.id;
    host = userMap[hostKey] ?? false;
    role = PlayerRoleExtension.of(userMap[roleKey]);
  }

  Map<String, dynamic> toJson() {
    var json = {idKey: id, nameKey: name, onlineKey: online, roleKey: role.toString()};
    if (host) {
      json[hostKey] = true;
    }
    return json;
  }
}

class Lobby {
  static const lobbiesKey = 'lobbies';
  static const infoKey = 'info';
  static const playersKey = 'players';
  static const gameKey = 'game';
  static const wordsKey = 'words';
  static const logKey = 'log';
}

class LobbyInfo {
  static const lockedKey = 'locked';

  late final bool locked;

  // late final GameState = BehaviorSubject<GameState>.seeded(GameState.preparing); // preparing while loading

  LobbyInfo({required this.locked});

  LobbyInfo.fromJson(Map<String, dynamic> lobbyMap, User currentUser) {
    locked = lobbyMap[lockedKey];
  }

  Map<String, dynamic> toJson() {
    return {
      lockedKey: locked,
    };
  }
}

enum GameState { preparing, redPlayersTurn, redMastersTurn, bluePlayersTurn, blueMastersTurn, redWon, blueWon }

class Clue {
  static const textKey = 'text';
  static const countKey = 'count';
  static const openedCountKey = 'openedCount';

  late final String text;
  late final int count;
  late final int openedCount;

  Clue({required this.text, required this.count, required this.openedCount});

  Clue.fromJson(Map<String, dynamic> lobbyMap) {
    text = lobbyMap[textKey];
    count = lobbyMap[countKey];
    openedCount = lobbyMap[openedCountKey];
  }

  Map<String, dynamic> toJson() {
    return {textKey: text, countKey: count, openedCountKey: openedCount};
  }
}

class Game {
  static const stateKey = 'state';
  static const dictionaryKey = 'dictionary';
  static const clueKey = 'clue';

  late final GameState state;
  late final String dictionary;
  late final Clue? clue;

  Game({required this.state, required this.clue, required this.dictionary});

  Game.fromJson(Map<String, dynamic> lobbyMap) {
    state = GameStateExtensions.of(lobbyMap[stateKey]);
    dictionary = lobbyMap[dictionaryKey];
    if (lobbyMap[clueKey] != null) {
      clue = Clue.fromJson(Map<String, dynamic>.from(lobbyMap[clueKey] as Map));
    } else {
      clue = null;
    }
  }

  Map<String, dynamic> toJson() {
    return {stateKey: state.toString(), clueKey: clue?.toJson(), dictionaryKey: dictionary};
  }
}

enum WordColor { red, blue, grey, black }

class Word {
  static const textKey = 'text';
  static const colorKey = 'color';
  static const revealedKey = 'revealed';

  late final String id; // not exposed
  late final String text;
  late final WordColor color;
  late final bool revealed; // exposed only if true

  Word({required this.id, required this.text, required this.color, this.revealed = false});

  Word.fromJson(Map<String, dynamic> lobbyMap, String index) {
    id = index;
    text = lobbyMap[textKey];
    color = WordColorExtensions.of(lobbyMap[colorKey]);
    revealed = lobbyMap[revealedKey] ?? false;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> word = {textKey: text, colorKey: color.toString()};
    if (revealed) {
      word[revealedKey] = revealed;
    }
    return word;
  }
}

class LogEntry {
  static const String textKey = 'text';
  static const String whoKey = 'who';
  static const String wordKey = 'word';

  late final String text;
  late final String? who; // exposed only if no null
  late final Word? word; // exposed only if no null

  LogEntry({required this.text, this.word, this.who});

  LogEntry.fromJson(Map<String, dynamic> lobbyMap) {
    text = lobbyMap[textKey];
    if (lobbyMap[wordKey] != null) {
      word = Word.fromJson(Map<String, dynamic>.from(lobbyMap[wordKey] as Map), ''); // we don't need id here
    } else {
      word = null;
    }
    who = lobbyMap[whoKey];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> entry = {textKey: text};

    if (who != null) {
      entry[whoKey] = who;
    }
    if (word != null) {
      entry[wordKey] = word!.toJson();
    }

    return entry;
  }
}
