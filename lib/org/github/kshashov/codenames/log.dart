import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/src/provider.dart';

class LogWidget extends StatelessWidget {
  final CrossAxisAlignment alignment;

  const LogWidget({Key? key, required this.alignment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<LobbyBloc>();

    return SeededStreamBuilder<List<LogEntry>>(
      stream: bloc.logs,
      builder: (context, snapshot) {
        return //Expanded(child:
            // shrinkWrap: true,
            Padding(
                padding: EdgeInsets.all(context.ui.padding),
                child: Column(
                    crossAxisAlignment: alignment,
                    children: snapshot.requireData.map((e) => entry(context, bloc, e)).toList()));
      },
    );
  }

  Widget entry(BuildContext context, LobbyBloc bloc, LogEntry entry) {
    return Wrap(spacing: context.ui.padding * 0.5, direction: Axis.horizontal, children: [
      // TODO user TextSpan instead of Wrap
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
