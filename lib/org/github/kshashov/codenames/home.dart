import 'package:codenames/org/github/kshashov/codenames/services/coordinator.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String name;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    name = widget.user.name;
  }

  @override
  Widget build(BuildContext context) {
    var lobbyCoordinator = context.watch<LobbyCoordinator>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
              width: 300,
              child: CustomTextField(
                context,
                'Lobby Id',
                controller: _controller,
                suffix: InkWell(
                  child: Text('Find', style: TextStyle(fontSize: context.ui.fontSize)),
                  onTap: () => Navigator.pushNamed(context, '/lobby/' + _controller.text),
                ),
              )),
          SizedBox(height: context.ui.padding),
          Text('or', style: TextStyle(fontSize: context.ui.fontSizeBig)),
          SizedBox(height: context.ui.padding),
          ElevatedButton(
            onPressed: name.isEmpty
                ? null
                : () {
                    lobbyCoordinator
                        .registerLobby(widget.user)
                        .then((value) => Navigator.pushNamed(context, '/lobby/' + value));
                  },
            child: Padding(
              padding: EdgeInsets.all(context.ui.padding),
              child: Text('Create Lobby', style: TextStyle(fontSize: context.ui.fontSizeBig)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
  }
}
