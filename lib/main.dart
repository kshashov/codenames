import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/home.dart';
import 'package:myapp/lobby.dart';
import 'package:myapp/services/coordinator.dart';
import 'package:myapp/services/lobby.dart';
import 'package:myapp/services/user.dart';
import 'package:provider/provider.dart';

import 'services/models.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY']!,
          authDomain: 'codenames-d55cd.firebaseapp.com',
          databaseURL: 'https://codenames-d55cd-default-rtdb.firebaseio.com',
          projectId: 'codenames-d55cd',
          storageBucket: 'codenames-d55cd.appspot.com',
          messagingSenderId: '51985242347',
          appId: '1:51985242347:web:ceca73924f6101fd4486ae',
          measurementId: 'G-SDX834227N'));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserBloc()),
        ChangeNotifierProvider(create: (_) => LobbyCoordinator())
      ],
      child: const CodeNamesApp(),
    ),
  );
}

class CodeNamesApp extends StatelessWidget {
  const CodeNamesApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Codenames',
        theme: ThemeData(
            backgroundColor: Colors.white,
            primarySwatch: Colors.indigo,
            chipTheme: Theme.of(context).chipTheme.copyWith(backgroundColor: Colors.grey[200]),
            shadowColor: Colors.grey[200],
            brightness: Brightness.light),
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
              settings: RouteSettings(name: settings.name),
              builder: (context) {
                var userBloc = context.watch<UserBloc>();
                return StreamBuilder<User>(
                    stream: userBloc.user,
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasData && (settings.name != null)) {
                        var uri = Uri.parse(settings.name!);

                        if (uri.pathSegments.length == 2 && uri.pathSegments.first == LobbyPage.route) {
                          var id = uri.pathSegments[1];

                          return FutureBuilder<bool>(
                            future: context.watch<LobbyCoordinator>().hasLobby(id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Scaffold(body: Text(snapshot.error.toString()));
                              }

                              if (!snapshot.hasData) {
                                return const Scaffold(body: Text('Searching for lobby'));
                              }

                              if (snapshot.requireData) {
                                return Provider<LobbyBloc>(
                                    create: (context) => LobbyBloc(id: id, user: userSnapshot.requireData),
                                    dispose: (context, value) => value.dispose(),
                                    builder: (context, child) => StreamBuilder<bool>(
                                          stream: context.watch<LobbyBloc>().loading,
                                          builder: (context, loadingSnapshot) =>
                                              loadingSnapshot.hasData && !loadingSnapshot.requireData
                                                  ? LobbyPage(
                                                      id: id,
                                                      user: userSnapshot.requireData,
                                                    )
                                                  : Scaffold(body: Text('Loading')),
                                        ));
                              } else {
                                return Scaffold(body: Text('Lobby not found!'));
                              }
                            },
                          );
                        } else {
                          // Home
                          return HomePage(
                            user: userSnapshot.requireData,
                          );
                        }
                      } else {
                        return const Text('loading');
                      }
                    });
              });
        });
  }
}
