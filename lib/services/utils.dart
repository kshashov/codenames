import 'models.dart';

extension PlayerRoleExtension on PlayerRole {
  bool get isMaster {
    switch (this) {
      case PlayerRole.redMaster:
        return true;
      case PlayerRole.blueMaster:
        return true;
      default:
        return false;
    }
  }

  bool get isPlayer {
    switch (this) {
      case PlayerRole.redPlayer:
        return true;
      case PlayerRole.bluePlayer:
        return true;
      default:
        return false;
    }
  }

  bool get isSpectator {
    switch (this) {
      case PlayerRole.spectator:
        return true;
      default:
        return false;
    }
  }

  bool get isRed {
    switch (this) {
      case PlayerRole.redPlayer:
        return true;
      case PlayerRole.redMaster:
        return true;
      default:
        return false;
    }
  }

  bool get isBlue {
    switch (this) {
      case PlayerRole.bluePlayer:
        return true;
      case PlayerRole.blueMaster:
        return true;
      default:
        return false;
    }
  }

  static PlayerRole of(String value) {
    return PlayerRole.values.firstWhere((element) => element.toString() == value);
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
