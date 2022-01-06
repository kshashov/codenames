import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/game.dart';
import 'package:myapp/player.dart';
import 'package:myapp/services/lobby.dart';
import 'package:myapp/services/models.dart';
import 'package:myapp/services/user.dart';
import 'package:myapp/services/utils.dart';
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
        child: Column(
          children: [
            LobbyHeader(),
            Expanded(
                child: Row(
              children: [
                Column(children: [
                  SeededStreamBuilder<PlayerRole>(
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
                  )
                ]),
                Expanded(child: GameWidget()),
                Column(children: [
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
                  )
                ])
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class LobbyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var userBloc = context.watch<UserBloc>();
    var bloc = context.watch<LobbyBloc>();
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
                          PlayerChip(player: snapshot.requireData)
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
                          context: context,
                          builder: (context) => LobbySummaryDialog(bloc, context.watch<UserBloc>()),
                        ),
                    label: const Icon(Icons.settings)),
              ),
            )
          ],
        ));
  }
}

class LobbySummaryDialog extends StatelessWidget {
  final LobbyBloc _lobbyBloc;
  final UserBloc _userBloc;
  late String _name;

  LobbySummaryDialog(this._lobbyBloc, this._userBloc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _name = _userBloc.user.valueOrNull!.name;

    var content = Flex(direction: Axis.vertical, mainAxisSize: MainAxisSize.min, children: [
      const Padding(
        padding: EdgeInsets.all(10),
        child: Text('Options', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
      ),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextFormField(
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Your Name:',
                suffix: TextButton(
                    onPressed: () {
                      if (_name.isEmpty) return;
                      _userBloc.rename(_name);
                      _lobbyBloc.renameUser(_name);
                    },
                    child: const Text('Save'))),
            initialValue: _name,
            onChanged: (value) => _name = value,
          )),
      const SizedBox(height: 10),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: PlayersWrap(
            players: _lobbyBloc.spectators,
            title: 'Spectators: ',
            direction: Axis.vertical,
            showIfNone: false,
          )),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(10),
            color: Theme.of(context).shadowColor,
            child: Column(
              children: [
                SeededStreamBuilder<Player>(
                  stream: _lobbyBloc.host,
                  builder: (context, snapshot) => hostButtons(snapshot.requireData.id == _lobbyBloc.user.id),
                ),
                const SizedBox(height: 10),
                SeededStreamBuilder<PlayerRole>(
                  stream: _lobbyBloc.userRole,
                  builder: (context, snapshot) => commonButtons(snapshot.requireData.isSpectator),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ))
        ],
      ),
    ]);

    return Dialog(
      elevation: 0,
      child: SizedBox(width: 400, child: content),
    );
  }

  Widget commonButtons(bool isSpectator) {
    return Wrap(
      spacing: 5,
      direction: Axis.horizontal,
      children: [
        if (!isSpectator)
          ElevatedButton(
            onPressed: () => _lobbyBloc.becomeSpectator(),
            child: const Text('Become Spectator'),
          ),
        // ElevatedButton(
        //   style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.redAccent)),
        //   onPressed: () => _lobbyBloc.leave(),
        //   child: const Text('Leave'),
        // )
      ],
    );
  }

  Widget hostButtons(bool isHost) {
    if (!isHost) return SizedBox.shrink();

    return Wrap(
      spacing: 5,
      direction: Axis.horizontal,
      children: [
        ElevatedButton(
          onPressed: () => _lobbyBloc.resetGame(),
          child: const Text('Reset'),
        ),
        SeededStreamBuilder<bool>(
          stream: _lobbyBloc.locked,
          builder: (context, snapshot) => lockButton(snapshot),
        ),
        // TODO make host
      ],
    );
  }

  Widget lockButton(AsyncSnapshot<bool> snapshot) {
    if (snapshot.requireData) {
      return ElevatedButton(
        onPressed: () => _lobbyBloc.unlockTeams(),
        child: const Text('Unlock Teams'),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _lobbyBloc.lockTeams(),
        child: const Text('Lock Teams'),
      );
    }
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
                  StreamBuilder(
                    stream: score,
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
                      child: PlayersWrap(title: 'Operatives:', players: players)),
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
                      child: PlayersWrap(title: 'Masters:', players: masters)),
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
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      width: 250,
      child: content,
    );
  }
}
