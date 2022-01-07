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
            const SizedBox(height: 20),
            GameHint(snapshot.requireData),
            WordsWidget(snapshot.requireData),
            !snapshot.requireData.isRed && !snapshot.requireData.isBlue
                ? const SizedBox.shrink()
                : Column(children: [
              ClueWidget(snapshot.requireData),
              const SizedBox(height: 10),
              GameActions(snapshot.requireData)
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
                padding: const EdgeInsets.all(15),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                crossAxisCount: 5,
                childAspectRatio: 2.5,
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: color, boxShadow: [
        BoxShadow(
            offset: Offset.fromDirection(1, 10), color: Theme.of(context).shadowColor, blurRadius: 8, spreadRadius: 3)
      ]),
      alignment: Alignment.center,
      height: 100,
      child: Text(word.text, style: TextStyle(color: textColor, fontSize: 15)),
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

  Widget neutral(context, String text) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 20)),
      padding: const EdgeInsets.all(10),
    );
  }
}

class ClueWidget extends StatelessWidget {
  GameState _gameState;

  ClueWidget(this._gameState, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<Clue?>(
        stream: bloc.clue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          const textStyle = TextStyle(fontSize: 20, color: Colors.white);
          final color = _gameState.isRed ? Colors.redAccent : Colors.blueAccent;

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Chip(
                padding: const EdgeInsets.all(15),
                label: Text(snapshot.requireData!.text),
                labelStyle: textStyle,
                backgroundColor: color,
                shadowColor: Theme.of(context).shadowColor,
                elevation: 10,
              ),
              const SizedBox(
                width: 10,
              ),
              Chip(
                padding: const EdgeInsets.all(15),
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
        style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(15))),
        child: const Text('End Turn', style: TextStyle(fontSize: 20)),
      );
    } else if (gameState.isMaster && playerRole.isMaster) {
      // master
      return Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Clue',
                  ),
                  onChanged: (value) => _clueText = value,
                )),
            const SizedBox(width: 10),
            SizedBox(
                width: 100,
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Count',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => _clueCount = int.parse(value),
                ))
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            onPressed: () {
              if (_clueText.isNotEmpty) bloc.sendClue(Clue(text: _clueText, count: _clueCount, openedCount: 0));
              resetClue();
            },
            style: ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(15))),
            child: const Text('Give Clue', style: TextStyle(fontSize: 20)))
      ]);
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
