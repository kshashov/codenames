import 'package:flutter/material.dart';
import 'package:myapp/utils.dart';

import 'services/models.dart';

class PlayersWrap extends StatelessWidget {
  final String? title;
  final Stream<List<Player>> players;
  final Axis direction;
  final bool showIfNone;

  PlayersWrap({Key? key, required this.players, this.title, this.direction = Axis.vertical, this.showIfNone = true})
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  // const SizedBox(height: 10),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Wrap(
                        spacing: 3,
                        children: [
                          for (var player in snapshot.requireData)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: PlayerChip(player: player),
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

  const PlayerChip({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var chip = Chip(label: Text(player.fullName), backgroundColor: Theme.of(context).chipTheme.backgroundColor);
    if (player.online) {
      return Badge(child: chip, top: 6, right: 6, minSize: 6);
    } else {
      return chip;
    }
  }
}
