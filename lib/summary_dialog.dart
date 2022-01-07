import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/player.dart';
import 'package:myapp/services/lobby.dart';
import 'package:myapp/services/models.dart';
import 'package:myapp/services/user.dart';
import 'package:myapp/services/utils.dart';
import 'package:myapp/utils.dart';
import 'package:provider/src/provider.dart';

class LobbySummaryDialog extends StatelessWidget {
  late LobbyBloc _lobbyBloc;
  late UserBloc _userBloc;
  late String _name;
  final BuildContext context;

  LobbySummaryDialog(this.context, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _lobbyBloc = this.context.watch<LobbyBloc>();
    _userBloc = this.context.watch<UserBloc>();
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
            context: this.context,
          )),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.all(10),
            color: Theme.of(this.context).shadowColor,
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
