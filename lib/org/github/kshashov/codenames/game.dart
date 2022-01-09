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
          return Column(children: [
            SizedBox(height: context.ui.padding),
            GameHint(snapshot.requireData),
            SizedBox(height: context.ui.padding),
            WordsWidget(snapshot.requireData),
            !snapshot.requireData.isRed && !snapshot.requireData.isBlue
                ? const SizedBox.shrink()
                : Column(children: [
                    ClueWidget(snapshot.requireData),
                    SizedBox(height: context.ui.padding),
                    GameActions(snapshot.requireData),
                    SizedBox(height: context.ui.paddingBig),
                  ])
          ]);
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
                padding: EdgeInsets.all(context.ui.paddingBig),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                mainAxisSpacing: context.ui.padding,
                crossAxisSpacing: context.ui.padding,
                crossAxisCount: 5,
                childAspectRatio: 2.8,
                children: wordsSnapshot.requireData
                    .map((e) => wordWidget(context, roleSnapshot.requireData, e, bloc))
                    .toList(growable: false),
              );
            }));
  }

  Widget wordWidget(BuildContext context, PlayerRole role, Word word, LobbyBloc bloc) {
    Color color;
    Color textColor;

    if (role.isMaster || word.revealed) {
      // Opened word
      textColor = Colors.white;
      color = word.color.flutterColor;
    } else {
      // Closed word
      color = Theme.of(context).cardColor;
      textColor = Colors.black;
    }

    final card = Container(
      key: Key(word.id),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(context.ui.radiusBig), color: color, boxShadow: [
        BoxShadow(
            offset: Offset.fromDirection(1, 10),
            color: Theme.of(context).shadowColor,
            blurRadius: context.ui.paddingBig * 0.7,
            spreadRadius: context.ui.paddingBig * 0.1)
      ]),
      alignment: Alignment.center,
      child: Text(word.text, style: TextStyle(color: textColor, fontSize: context.ui.fontSize)),
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
      return neutral(context, 'Wait for the game to start');
    }

    if (gameState == GameState.redWon) {
      return neutral(context, 'Red team wins!');
    }

    if (gameState == GameState.blueWon) {
      return neutral(context, 'Blue team wins');
    }

    if (playerRole.isSpectator) {
      var color = gameState.isRed ? 'Red' : 'Blue';
      var who = gameState.isMaster ? 'spymasters' : 'operatives';
      return neutral(context, "$color $who are playing. (To play, you need to join a team)");
    } else {
      if (gameState.isRed != playerRole.isRed) {
        // Not your team turn
        var who = gameState.isMaster ? 'spymasters' : 'operatives';
        return neutral(context, "The opponent $who are playing, wait for your turn");
      } else {
        // Your team turn
        if (gameState.isPlayer) {
          // Your players turn
          if (playerRole.isPlayer) {
            return neutral(context, 'Try to guess a word');
          } else {
            return neutral(context, 'Your operatives are guessing now');
          }
        } else if (gameState.isMaster) {
          // Your masters turn
          if (playerRole.isMaster) {
            return neutral(context, 'Give your operatives a clue');
          } else {
            return neutral(context, 'Wait for your spymasters to give a clue');
          }
        }
      }
    }

    return const SizedBox.shrink();
  }

  Widget neutral(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Chip(
        label: Text(text, style: TextStyle(fontSize: context.ui.fontSizeBig)),
        padding: EdgeInsets.all(context.ui.padding),
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
            padding: EdgeInsets.all(context.ui.padding),
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
      return FittedBox(
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            SizedBox(
                width: 200,
                height: context.ui.fontSizeBig + 3 * context.ui.padding,
                child: TextFormField(
                  style: TextStyle(fontSize: context.ui.fontSizeBig),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Clue',
                  ),
                  onChanged: (value) => _clueText = value,
                )),
            SizedBox(width: context.ui.padding),
            SizedBox(
                width: 100, // TODO size
                height: context.ui.fontSizeBig + 3 * context.ui.padding,
                child: TextField(
                  style: TextStyle(fontSize: context.ui.fontSizeBig),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Count',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _clueCount = int.parse(value),
                )),
            SizedBox(width: context.ui.padding),
            ElevatedButton(
                onPressed: () {
                  if (_clueText.isNotEmpty) bloc.sendClue(Clue(text: _clueText, count: _clueCount, openedCount: 0));
                  resetClue();
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.ui.radiusBig))),
                    padding: MaterialStateProperty.all(EdgeInsets.all(context.ui.paddingBig))),
                child: Text('Give Clue', style: TextStyle(fontSize: context.ui.fontSizeBig)))
          ]));
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
