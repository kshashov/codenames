import 'package:flutter/material.dart';

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

extension GameStateExtensions on GameState {
  bool get isRed {
    switch (this) {
      case GameState.redPlayersTurn:
        return true;
      case GameState.redMastersTurn:
        return true;
      case GameState.redWon:
        return true;
      default:
        return false;
    }
  }

  bool get isBlue {
    switch (this) {
      case GameState.bluePlayersTurn:
        return true;
      case GameState.blueMastersTurn:
        return true;
      case GameState.blueWon:
        return true;
      default:
        return false;
    }
  }

  bool get isEnd {
    switch (this) {
      case GameState.blueWon:
        return true;
      case GameState.redWon:
        return true;
      default:
        return false;
    }
  }

  bool get isMaster {
    switch (this) {
      case GameState.redMastersTurn:
        return true;
      case GameState.blueMastersTurn:
        return true;
      default:
        return false;
    }
  }

  bool get isPlayer {
    switch (this) {
      case GameState.redPlayersTurn:
        return true;
      case GameState.bluePlayersTurn:
        return true;
      default:
        return false;
    }
  }

  static GameState of(String value) {
    return GameState.values.firstWhere((element) => element.toString() == value);
  }
}

extension WordColorExtensions on WordColor {
  static WordColor of(String value) {
    return WordColor.values.firstWhere((element) => element.toString() == value);
  }

  Color get flutterColor {
    switch (this) {
      case WordColor.black:
        return Colors.black;
      case WordColor.red:
        return Colors.redAccent;
      case WordColor.blue:
        return Colors.blueAccent;
      default:
        return Colors.grey.shade600;
    }
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
