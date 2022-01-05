import 'package:myapp/services/utils.dart';
import 'package:uuid/uuid.dart';

class User {
  late String id;
  late String name;

  User(this.id, this.name);

  User.fromJson(Map<dynamic, dynamic> userMap) {
    const uuid = Uuid();
    id = userMap['id'] ?? uuid.v1();
    name = userMap['name'] ?? "NoName";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

enum PlayerRole { spectator, bluePlayer, blueMaster, redPlayer, redMaster }

class Player {
  static const playersKey = 'players';
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
