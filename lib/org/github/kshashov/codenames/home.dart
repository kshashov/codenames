import 'package:codenames/org/github/kshashov/codenames/services/coordinator.dart';
import 'package:codenames/org/github/kshashov/codenames/services/models.dart';
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

  @override
  void initState() {
    super.initState();
    name = widget.user.name;
  }

  @override
  Widget build(BuildContext context) {
    var lobbyCoordinator = context.watch<LobbyCoordinator>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedButton(
            onPressed: name.isEmpty
                ? null
                : () {
                    lobbyCoordinator
                        .registerLobby(widget.user)
                        .then((value) => Navigator.pushNamed(context, '/lobby/' + value));
                  },
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Text('Create Lobby', style: TextStyle(fontSize: 30)),
            ),
          ),
        ],
      ),
    );
  }
}
