import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/user.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class PlayersWrap extends StatelessWidget {
  final String? title;
  final Stream<List<Player>> players;
  final Axis direction;
  final bool showIfNone;
  final BuildContext context;

  PlayersWrap(
      {Key? key,
      required this.players,
      this.title,
      this.direction = Axis.vertical,
      this.showIfNone = true,
      required this.context})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Player>>(
        stream: players,
        initialData: const [],
        builder: (context, snapshot) => (snapshot.requireData.isNotEmpty || showIfNone)
            ? Flex(
                direction: direction,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.ui.fontSize),
                    ),
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: context.ui.padding * 0.5),
                      child: Wrap(
                        spacing: context.ui.paddingSmall * 0.3,
                        runSpacing: context.ui.paddingSmall * 0.3,
                        children: [
                          for (var player in snapshot.requireData)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: context.ui.padding * 0.25),
                              child: PlayerChip(
                                player: player,
                                context: this.context,
                              ),
                            )
                        ],
                      ))
                ],
              )
            : const SizedBox.shrink());
  }
}

class PlayerChip extends StatelessWidget {
  final Player player;
  final BuildContext context;

  const PlayerChip({Key? key, required this.player, required this.context}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userBloc = this.context.watch<UserBloc>();
    final bloc = this.context.watch<LobbyBloc>();

    Widget chip = Chip(
        padding: EdgeInsets.all(this.context.ui.paddingSmall * 0.4),
        label: Text(
          player.fullName,
          style: TextStyle(fontSize: this.context.ui.fontSize),
        ),
        backgroundColor: Theme.of(context).chipTheme.backgroundColor);
    if (player.online) {
      chip = Badge(child: chip, top: 6, right: 6, minSize: 6); // TODO size: mb leave size fixed?
    }

    return SeededStreamBuilder<Player>(
        stream: bloc.host,
        builder: (context, snapshot) {
          var user = userBloc.user.valueOrNull;
          if ((snapshot.requireData.id == user?.id) && (player.id != user?.id)) {
            return PopupMenuButton(
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  onTap: () => bloc.makeHost(player),
                  child: const Text("Make host"),
                )
              ],
              child: chip,
            );
          }

          return chip;
        });
  }
}
