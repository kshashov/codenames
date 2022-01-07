import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/game.dart';
import 'package:myapp/log.dart';
import 'package:myapp/player.dart';
import 'package:myapp/services/lobby.dart';
import 'package:myapp/services/models.dart';
import 'package:myapp/services/user.dart';
import 'package:myapp/services/utils.dart';
import 'package:myapp/summary_dialog.dart';
import 'package:myapp/utils.dart';
import 'package:provider/src/provider.dart';

class LobbyPage extends StatefulWidget {
  static const String route = 'lobby';
  final User user;
  final String id;

  const LobbyPage({Key? key, required this.id, required this.user}) : super(key: key);

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late String name;
  late LobbyBloc _bloc;

  @override
  void initState() {
    super.initState();
    name = widget.user.name;
  }

  @override
  Widget build(BuildContext context) {
    _bloc = context.watch<LobbyBloc>();

    return Scaffold(
        body: Center(
            child: Container(
      constraints: BoxConstraints(minWidth: 500, maxWidth: 1500),
      child: Column(
        children: [
          LobbyHeader(),
          Expanded(
              child: Row(
            children: [
              Column(children: [
                Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    width: 250,
                    child: SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) => TeamWidget(
                          title: 'RED TEAM',
                          color: Colors.redAccent,
                          onBecomeMaster: () => _bloc.becomeRedMaster(),
                          onBecomePlayer: () => _bloc.becomeRedPlayer(),
                          score: _bloc.redScore,
                          masters: _bloc.redMasters,
                          players: _bloc.redPlayers,
                          currentTeam: snapshot.requireData.isRed),
                    ))
              ]),
              Expanded(child: GameWidget()),
              Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  width: 250,
                  child: Column(children: [
                    SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) => TeamWidget(
                          title: 'BLUE TEAM',
                          color: Colors.blueAccent,
                          onBecomeMaster: () => _bloc.becomeBlueMaster(),
                          onBecomePlayer: () => _bloc.becomeBluePlayer(),
                          score: _bloc.blueScore,
                          masters: _bloc.blueMasters,
                          players: _bloc.bluePlayers,
                          currentTeam: snapshot.requireData.isBlue),
                    ),
                    LogWidget()
                  ]))
            ],
          ))
        ],
      ),
    )));
  }
}

class LobbyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userBloc = context.watch<UserBloc>();
    final bloc = context.watch<LobbyBloc>();
    final savedContext = context;

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            IconButton(
                tooltip: 'Home',
                onPressed: () {
                  Navigator.pushNamed(context, "/");
                },
                icon: const Icon(Icons.home_filled)),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SeededStreamBuilder<User>(
                  stream: userBloc.user,
                  builder: (context, snapshot) => Text("Hello ${snapshot.requireData.name}"),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Flutter Codenames Lobby',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    SeededStreamBuilder<Player>(
                      stream: bloc.host,
                      builder: (context, snapshot) => Flex(
                        direction: Axis.horizontal,
                        children: [
                          const Text('by'),
                          const SizedBox(
                            width: 5,
                          ),
                          PlayerChip(
                            player: snapshot.requireData,
                            context: context,
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            )),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SeededStreamBuilder(
                stream: bloc.online,
                builder: (context, snapshot) => OutlinedButton.icon(
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0))),
                        padding: MaterialStateProperty.all(const EdgeInsets.all(20))),
                    icon: Text(
                      "Online: ${snapshot.data}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => showDialog(
                          context: savedContext,
                          builder: (context) => LobbySummaryDialog(savedContext),
                        ),
                    label: const Icon(Icons.settings)),
              ),
            )
          ],
        ));
  }
}

class TeamWidget extends StatelessWidget {
  final MaterialAccentColor color;
  final Function() onBecomeMaster;
  final Function() onBecomePlayer;
  final Stream<int> score;
  final Stream<List<Player>> masters;
  final Stream<List<Player>> players;
  final bool currentTeam;
  final String title;

  late LobbyBloc _bloc;

  TeamWidget(
      {Key? key,
      required this.title,
      required this.color,
      required this.onBecomeMaster,
      required this.onBecomePlayer,
      required this.score,
      required this.masters,
      required this.players,
      required this.currentTeam})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    _bloc = context.watch<LobbyBloc>();

    var content = SeededStreamBuilder<bool>(
        stream: _bloc.locked,
        builder: (context, locked) => Column(
              children: [
                Column(children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color.shade700,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 15,
                    color: color.shade100,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<int>(
                    stream: score,
                    initialData: 0,
                    builder: (context, snapshot) => Text(
                      "${snapshot.requireData} words left",
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Divider(
                  //   height: 15,
                  //   color: color.shade100,
                  // ),
                  const SizedBox(height: 10),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: PlayersWrap(title: 'Operatives:', players: players, context: context)),
                  SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) =>
                          (!locked.requireData && (!currentTeam || !snapshot.requireData.isPlayer))
                              ? OutlinedButton(
                                  child: const Text('Become Operative'), onPressed: () => onBecomePlayer.call())
                              : const SizedBox.shrink())
                ]),
                const SizedBox(height: 10),
                Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: PlayersWrap(
                        title: 'Masters:',
                        players: masters,
                        context: context,
                      )),
                  SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) => (!locked.requireData &&
                              (!currentTeam || !snapshot.requireData.isMaster))
                          ? OutlinedButton(child: const Text('Become Master'), onPressed: () => onBecomeMaster.call())
                          : const SizedBox.shrink())
                ]),
              ],
            ));

    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                offset: Offset.fromDirection(1, 10),
                color: Theme.of(context).shadowColor,
                blurRadius: 20,
                spreadRadius: 5)
          ]),
      child: content,
    );
  }
}
