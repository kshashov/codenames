import 'dart:math';

import 'package:codenames/org/github/kshashov/codenames/responsive.dart';
import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/src/provider.dart';

class GameWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<GameState>(
        stream: bloc.state,
        builder: (context, snapshot) {
          return SingleChildScrollView(
              child: Column(children: [
            GameHint(snapshot.requireData),
            WordsWidget(snapshot.requireData),
            !snapshot.requireData.isRed && !snapshot.requireData.isBlue
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.ui.padding),
                    child: Flex(
                        direction: (context.ui.size == ResponsiveSize.xl || !context.preferHorizontal)
                            ? Axis.vertical
                            : Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClueWidget(snapshot.requireData),
                          SizedBox(width: context.ui.paddingSmall, height: context.ui.paddingSmall),
                          GameActions(snapshot.requireData),
                        ]))
          ]));
        });
  }
}

class WordsWidget extends StatelessWidget {
  final GameState _gameState;

  const WordsWidget(this._gameState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<PlayerRole>(
        stream: bloc.userRole,
        builder: (context, roleSnapshot) => SeededStreamBuilder<List<Word>>(
            stream: bloc.words,
            builder: (context, wordsSnapshot) {
              return GridView.count(
                padding: EdgeInsets.all(context.ui.paddingSmall),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: context.ui.paddingSmall,
                crossAxisSpacing: context.ui.paddingSmall,
                crossAxisCount: 5,
                childAspectRatio: 2.8,
                children: wordsSnapshot.requireData
                    .map((e) => wordWidget(context, roleSnapshot.requireData, e, _gameState, bloc))
                    .toList(growable: false),
              );
            }));
  }

  Widget _transitionBuilder(Widget widget, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: widget,
      builder: (context, widget) {
        final isUnder = (const ValueKey('true') != widget!.key);
        final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value),
          child: widget,
          alignment: Alignment.center,
        );
      },
    );
  }

  Widget _tiltTransitionBuilder(Widget widget, Animation<double> animation) {
    final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
    return AnimatedBuilder(
      animation: rotateAnim,
      child: widget,
      builder: (context, widget) {
        final isUnder = (const ValueKey('true') != widget!.key);
        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
        tilt *= isUnder ? -1.0 : 1.0;
        final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
        return Transform(
          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
          child: widget,
          alignment: Alignment.center,
        );
      },
    );
  }

  Widget wordWidget(BuildContext context, PlayerRole role, Word word, GameState gameState, LobbyBloc bloc) {
    Color color;
    Color textColor;
    bool opened;

    bool isLikeMaster = role.isMaster || gameState.isEnd;

    if (isLikeMaster || word.revealed) {
      // Opened word
      textColor = Colors.white;
      color = word.color.flutterColor;
      opened = true;
    } else {
      // Closed word
      color = Theme.of(context).cardColor;
      textColor = Colors.black;
      opened = false;
    }

    Color? backColor;
    Border? border;
    // Decide should we use color as background or border
    if (isLikeMaster && !word.revealed) {
      // Word is not revealed but user is master
      border = Border.all(color: color, width: context.ui.paddingSmall * 0.5);
      backColor = Colors.white;
      textColor = Colors.black;
    } else {
      // Word is revealed for all
      backColor = color;
    }

    Widget card = Container(
      key: Key(opened.toString()),
      decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(context.ui.radiusBig),
          color: backColor,
          boxShadow: [
            BoxShadow(
                offset: Offset.fromDirection(1, 10),
                color: Theme.of(context).shadowColor,
                blurRadius: context.ui.paddingBig * 0.7,
                spreadRadius: context.ui.paddingBig * 0.1)
          ]),
      alignment: Alignment.center,
      child: Text(word.text, style: TextStyle(color: textColor, fontSize: context.ui.fontSize)),
    );

    card = AnimatedSwitcher(
      duration: const Duration(milliseconds: 1600),
      transitionBuilder: _tiltTransitionBuilder,
      layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
      child: card,
      switchInCurve: Curves.easeInBack,
      switchOutCurve: Curves.easeInBack.flipped,
    );

    if (((_gameState == GameState.bluePlayersTurn) && (role == PlayerRole.bluePlayer)) ||
        ((_gameState == GameState.redPlayersTurn) && (role == PlayerRole.redPlayer))) {
      // Make clickable for current player
      return GestureDetector(key: Key(word.id), onTap: () => bloc.revealWord(word), child: card);
    }

    return card;
  }
}

class GameHint extends StatelessWidget {
  final GameState _gameState;

  const GameHint(this._gameState);

  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<PlayerRole>(
        stream: bloc.userRole,
        builder: (context, userRoleSnapshot) => buildUserHint(context, _gameState, userRoleSnapshot.requireData));
  }

  buildUserHint(BuildContext context, GameState gameState, PlayerRole playerRole) {
    if (gameState == GameState.preparing) {
      return coloredHint(context, 'Wait for the game to start', gameState);
    }

    if (gameState == GameState.redWon) {
      return coloredHint(context, 'Red team wins!', gameState);
    }

    if (gameState == GameState.blueWon) {
      return coloredHint(context, 'Blue team wins', gameState);
    }

    if (playerRole.isSpectator) {
      var color = gameState.isRed ? 'Red' : 'Blue';
      var who = gameState.isMaster ? 'spymasters' : 'operatives';
      return coloredHint(context, "$color $who are playing. (To play, you need to join a team)", gameState);
    } else {
      if (gameState.isRed != playerRole.isRed) {
        // Not your team turn
        var who = gameState.isMaster ? 'spymasters' : 'operatives';
        return coloredHint(context, "The opponent $who are playing, wait for your turn", gameState);
      } else {
        // Your team turn
        if (gameState.isPlayer) {
          // Your players turn
          if (playerRole.isPlayer) {
            return coloredHint(context, 'Try to guess a word', gameState);
          } else {
            return coloredHint(context, 'Your operatives are guessing now', gameState);
          }
        } else if (gameState.isMaster) {
          // Your masters turn
          if (playerRole.isMaster) {
            return coloredHint(context, 'Give your operatives a clue', gameState);
          } else {
            return coloredHint(context, 'Wait for your spymasters to give a clue', gameState);
          }
        }
      }
    }

    return const SizedBox.shrink();
  }

  Widget coloredHint(BuildContext context, String text, GameState gameState) {
    if (gameState.isBlue) {
      return hint(context, text, Colors.blueAccent, Colors.white);
    } else if (gameState.isRed) {
      return hint(context, text, Colors.redAccent, Colors.white);
    }
    return hint(context, text, null, null);
  }

  Widget hint(BuildContext context, String text, Color? background, Color? textColor) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            child: child,
            // position: Tween<Offset>(begin: Offset(0.0, -0.5), end: Offset(0.0, 0.0)).animate(animation),
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
          );
        },
        child: Chip(
            key: Key(text),
            backgroundColor: background,
            label: Text(text, style: TextStyle(fontSize: context.ui.fontSizeBig, color: textColor)),
            padding: EdgeInsets.all(context.ui.padding)),
      ),
    );
  }
}

class ClueWidget extends StatelessWidget {
  final GameState _gameState;

  const ClueWidget(this._gameState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<Clue?>(
        stream: bloc.clue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final textStyle = TextStyle(fontSize: context.ui.fontSize, color: Colors.white);
          final color = _gameState.isRed ? Colors.redAccent : Colors.blueAccent;

          return Padding(
            padding: EdgeInsets.all(context.ui.paddingSmall),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Chip(
                padding: EdgeInsets.all(context.ui.padding),
                label: Text(snapshot.requireData!.text),
                labelStyle: textStyle,
                backgroundColor: color,
                shadowColor: Theme.of(context).shadowColor,
                elevation: 10,
              ),
              SizedBox(width: context.ui.padding),
              Chip(
                padding: EdgeInsets.all(context.ui.padding),
                label: Text(snapshot.requireData!.count.toString()),
                labelStyle: textStyle,
                backgroundColor: color,
                shadowColor: Theme.of(context).shadowColor,
                elevation: 10,
              )
            ]),
          );
        });
  }
}

class GameActions extends StatefulWidget {
  final GameState _gameState;

  const GameActions(this._gameState, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GameActionState();
}

class _GameActionState extends State<GameActions> {
  String _clueText = '';
  int _clueCount = 1;

  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();
    return SeededStreamBuilder<PlayerRole>(
      stream: bloc.userRole,
      builder: (context, userRoleSnapshot) =>
          buildUserAction(context, bloc, widget._gameState, userRoleSnapshot.requireData),
    );
  }

  Widget buildUserAction(BuildContext context, LobbyBloc bloc, GameState gameState, PlayerRole playerRole) {
    if (playerRole.isSpectator || (gameState.isRed != playerRole.isRed)) {
      // if spectator or opponent team
      resetClue();
      return const SizedBox.shrink();
    }

    // if same team
    if (gameState.isPlayer && playerRole.isPlayer) {
      // player
      resetClue();
      return ElevatedButton(
        onPressed: () => bloc.endPlayerTurn(),
        style: ButtonStyle(
            shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.ui.radiusBig))),
            padding: MaterialStateProperty.all(EdgeInsets.all(context.ui.paddingBig))),
        child: Text('End Turn', style: TextStyle(fontSize: context.ui.fontSizeBig)),
      );
    } else if (gameState.isMaster && playerRole.isMaster) {
      // master
      return Container(
          width: 400,
          child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 180,
                        child: CustomTextField(context, 'Clue',
                            suffix: const Text(''), onChanged: (value) => _clueText = value)),
                    SizedBox(width: context.ui.padding),
                    SizedBox(
                        width: 100,
                        child: CustomTextField(context, 'Count',
                            suffix: const Text(''),
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) => _clueCount = int.parse(value))),
                    SizedBox(width: context.ui.padding),
                    ElevatedButton(
                        onPressed: () {
                          if (_clueText.isNotEmpty)
                            bloc.sendClue(Clue(text: _clueText, count: _clueCount, openedCount: 0));
                          resetClue();
                        },
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.ui.radiusBig))),
                            padding: MaterialStateProperty.all(EdgeInsets.all(context.ui.paddingBig))),
                        child: Text('Give Clue', style: TextStyle(fontSize: context.ui.fontSizeBig)))
                  ])));
    }

    resetClue();
    // player or your teammate turn
    return const SizedBox.shrink();
  }

  resetClue() {
    _clueCount = 1;
    _clueText = '';
  }
}
