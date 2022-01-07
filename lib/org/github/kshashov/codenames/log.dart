import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/src/provider.dart';

class LogWidget extends StatelessWidget {
  const LogWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<List<LogEntry>>(
        stream: bloc.logs,
        builder: (context, snapshot) => Expanded(
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.requireData.map((e) => entry(context, bloc, e)).toList(),
                  ),
                ))));
  }

  Widget entry(BuildContext context, LobbyBloc bloc, LogEntry entry) {
    return Wrap(spacing: 5, direction: Axis.horizontal, children: [
      if (entry.who != null) Text(entry.who!),
      Text(entry.text),
      if (entry.word != null)
        Text(
          entry.word!.text,
          style: TextStyle(color: entry.word!.color.flutterColor),
        )
    ]);
  }
}
