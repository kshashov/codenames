import 'package:codenames/org/github/kshashov/codenames/player.dart';
import 'package:codenames/org/github/kshashov/codenames/services/lobby.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/services/user.dart';
import 'package:codenames/org/github/kshashov/codenames/services/utils.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      SeededStreamBuilder<PlayerRole>(
        stream: _lobbyBloc.userRole,
        builder: (context, snapshot) => commonButtons(snapshot.requireData.isSpectator),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
              child: Container(
            color: Theme.of(this.context).shadowColor,
            child: Column(
              children: [
                SeededStreamBuilder<Player>(
                  stream: _lobbyBloc.host,
                  builder: (context, snapshot) => hostButtons(snapshot.requireData.id == _lobbyBloc.user.id),
                ),
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
      ],
    );
  }

  Widget hostButtons(bool isHost) {
    if (!isHost) return const SizedBox.shrink();

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Flex(
          direction: Axis.vertical,
          children: [
            _DictionaryField(_lobbyBloc),
            const SizedBox(height: 10),
            SeededStreamBuilder<bool>(
              stream: _lobbyBloc.locked,
              builder: (context, snapshot) => lockButton(snapshot),
            ),
          ],
        ));
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

class _DictionaryField extends StatefulWidget {
  final LobbyBloc _bloc;

  const _DictionaryField(this._bloc, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DictionaryFieldState();
}

class _DictionaryFieldState extends State<_DictionaryField> {
  late TextEditingController _controller;
  late FToast fToast;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget._bloc.dictionary.valueOrNull);
    fToast = FToast();
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return SeededStreamBuilder<String>(
      stream: widget._bloc.dictionary,
      builder: (context, snapshot) {
        return Column(children: [
          TextFormField(
            decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Words Pack:',
                suffix: Wrap(children: [
                  TextButton(
                      onPressed: () {
                        _controller.value = _controller.value.copyWith(text: LobbyBloc.enPackUri);
                      },
                      child: const Text('EN')),
                  TextButton(
                      onPressed: () {
                        _controller.value = _controller.value.copyWith(text: LobbyBloc.ruPackUri);
                      },
                      child: const Text('RU'))
                ])),
            controller: _controller,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              try {
                print(_controller.text);
                await widget._bloc.tryStartGame(_controller.text);
              } catch (ex) {
                fToast.showToast(
                  toastDuration: const Duration(seconds: 7),
                  child: Chip(
                    label: Text(
                      ex.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Start Game'),
          )
        ]);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
