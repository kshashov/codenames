import 'dart:ui';

import 'package:codenames/org/github/kshashov/codenames/game.dart';
import 'package:codenames/org/github/kshashov/codenames/log.dart';
import 'package:codenames/org/github/kshashov/codenames/player.dart';
import 'package:codenames/org/github/kshashov/codenames/responsive.dart';
import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/user.dart';
import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:codenames/org/github/kshashov/codenames/summary_dialog.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    return Center(
        child: Container(
      constraints: const BoxConstraints(minWidth: ResponsiveUtils.xlWidth, maxWidth: ResponsiveUtils.xlWidth),
      child: Column(
        children: [LobbyHeader(), Expanded(child: content(context))],
      ),
    ));
  }

  Widget content(BuildContext context) {
    var redTeam = SeededStreamBuilder<PlayerRole>(
      stream: _bloc.userRole,
      builder: (context, snapshot) => TeamWidget(
          title: 'RED',
          color: Colors.redAccent,
          onBecomeMaster: () => _bloc.becomeRedMaster(),
          onBecomePlayer: () => _bloc.becomeRedPlayer(),
          score: _bloc.redScore,
          masters: _bloc.redMasters,
          players: _bloc.redPlayers,
          currentTeam: snapshot.requireData.isRed),
    );
    var blueTeam = SeededStreamBuilder<PlayerRole>(
      stream: _bloc.userRole,
      builder: (context, snapshot) => TeamWidget(
          title: 'BLUE',
          color: Colors.blueAccent,
          onBecomeMaster: () => _bloc.becomeBlueMaster(),
          onBecomePlayer: () => _bloc.becomeBluePlayer(),
          score: _bloc.blueScore,
          masters: _bloc.blueMasters,
          players: _bloc.bluePlayers,
          currentTeam: snapshot.requireData.isBlue),
    );

    return context.preferHorizontal ? horizontal(context, redTeam, blueTeam) : vertical(context, redTeam, blueTeam);
  }

  Widget horizontal(
    BuildContext context,
    SeededStreamBuilder<PlayerRole> redTeam,
    SeededStreamBuilder<PlayerRole> blueTeam,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
            fit: FlexFit.tight, flex: 2, child: Container(margin: EdgeInsets.all(context.ui.padding), child: redTeam)),
        Flexible(flex: 6, child: GameWidget()),
        Flexible(flex: 2, child: Container(margin: EdgeInsets.all(context.ui.padding), child: blueTeam)),
      ],
    );
  }

  Widget vertical(
    BuildContext context,
    SeededStreamBuilder<PlayerRole> redTeam,
    SeededStreamBuilder<PlayerRole> blueTeam,
  ) {
    return Column(
      children: [
        GameWidget(),
        Flexible(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
              flex: 2,
              child: Container(
                margin: EdgeInsets.all(context.ui.padding),
                child: redTeam,
              )),
          Flexible(
              flex: 3,
              fit: FlexFit.tight,
              child: SingleChildScrollView(
                  controller: ScrollController(),
                  scrollDirection: Axis.vertical,
                  child: LogWidget(
                    context: context,
                    alignment:
                        context.ui.size == ResponsiveSize.xs ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  ))),
          Flexible(
              flex: 2,
              child: Container(
                margin: EdgeInsets.all(context.ui.padding),
                child: blueTeam,
              ))
        ])),
      ],
    );
  }
}

class LobbyHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userBloc = context.watch<UserBloc>();
    final bloc = context.watch<LobbyBloc>();
    final savedContext = context;

    return Padding(
        padding: EdgeInsets.zero, //all(context.ui.padding),
        child: Flex(
          direction: Axis.horizontal,
          children: [
            IconButton(
                tooltip: 'Home',
                onPressed: () {
                  Navigator.pushNamed(context, "/");
                },
                icon: const Icon(Icons.home_filled)),
            SizedBox(width: context.ui.paddingBig),
            Expanded(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (context.ui.size == ResponsiveSize.xl)
                  SeededStreamBuilder<User>(
                    stream: userBloc.user,
                    builder: (context, snapshot) => Text("Hello ${snapshot.requireData.name}"),
                  ),
                FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          (context.ui.size != ResponsiveSize.xs) ? 'Flutter Codenames Lobby' : 'Codenames Lobby',
                          style: TextStyle(fontSize: context.ui.fontSizeBig, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: context.ui.padding),
                        SeededStreamBuilder<Player>(
                          stream: bloc.host,
                          builder: (context, snapshot) => Flex(
                            direction: Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('by'),
                              SizedBox(width: context.ui.padding * 0.5),
                              PlayerChip(
                                player: snapshot.requireData,
                                context: context,
                              )
                            ],
                          ),
                        )
                      ],
                    ))
              ],
            )),
            if (context.preferHorizontal)
              Padding(
                padding: EdgeInsets.all(context.ui.paddingSmall),
                child: OutlinedButton(
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.ui.radiusBig))),
                        padding: MaterialStateProperty.all(EdgeInsets.all(context.ui.padding))),
                    child: const Text("History", style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => showDialog(
                          context: savedContext,
                          builder: (context) => LogWidget.dialog(savedContext, CrossAxisAlignment.start),
                        )),
              ),
            Padding(
              padding: EdgeInsets.all(context.ui.paddingSmall),
              child: SeededStreamBuilder(
                stream: bloc.online,
                builder: (context, snapshot) => OutlinedButton.icon(
                    style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.ui.radiusBig))),
                        padding: MaterialStateProperty.all(EdgeInsets.all(context.ui.padding))),
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
        builder: (context, locked) => SingleChildScrollView(
                child: Column(
              children: [
                Column(children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color.shade700,
                      fontWeight: FontWeight.w900,
                      fontSize: context.ui.fontSizeBig,
                    ),
                  ),
                  SizedBox(height: context.ui.paddingBig),
                  StreamBuilder<int>(
                    stream: score,
                    initialData: 0,
                    builder: (context, snapshot) => Text(
                      "${snapshot.requireData} words left",
                      style: TextStyle(fontSize: context.ui.fontSize),
                    ),
                  ),
                  SizedBox(height: context.ui.paddingSmall),
                  Divider(
                    height: context.ui.padding,
                    color: color.shade100,
                  ),
                  SizedBox(height: context.ui.paddingSmall),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.ui.padding),
                      child: PlayersWrap(title: 'Operatives:', players: players, context: context)),
                  SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) =>
                          (!locked.requireData && (!currentTeam || !snapshot.requireData.isPlayer))
                              ? OutlinedButton(
                                  child: Text('Join', style: TextStyle(fontSize: context.ui.fontSize)),
                                  onPressed: () => onBecomePlayer.call())
                              : const SizedBox.shrink())
                ]),
                SizedBox(height: context.ui.padding),
                Column(children: [
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.ui.padding),
                      child: PlayersWrap(
                        title: 'Masters:',
                        players: masters,
                        context: context,
                      )),
                  SeededStreamBuilder<PlayerRole>(
                      stream: _bloc.userRole,
                      builder: (context, snapshot) =>
                          (!locked.requireData && (!currentTeam || !snapshot.requireData.isMaster))
                              ? OutlinedButton(
                                  child: Text('Join', style: TextStyle(fontSize: context.ui.fontSize)),
                                  onPressed: () => onBecomeMaster.call())
                              : const SizedBox.shrink())
                ]),
              ],
            )));

    return Container(
      padding: EdgeInsets.all(context.ui.padding),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.ui.radiusBig),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                offset: Offset.fromDirection(1, 10),
                color: Theme.of(context).shadowColor,
                blurRadius: context.ui.paddingBig,
                spreadRadius: context.ui.paddingBig / 3)
          ]),
      child: SingleChildScrollView(controller: ScrollController(), scrollDirection: Axis.vertical, child: content),
    );
  }
}
