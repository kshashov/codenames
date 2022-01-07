import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CodeNamesPage extends StatelessWidget {
  final Widget child;

  const CodeNamesPage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Expanded(child: child),
        Padding(
            padding: const EdgeInsets.all(5),
            child: InkWell(
                child: Text('github/kshashov/codenames'), onTap: () => launch('https://github.com/kshashov/codenames')))
      ]),
    );
  }
}

class TextPage extends StatelessWidget {
  final String text;

  const TextPage(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CodeNamesPage(
        child: Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
      ),
    ));
  }
}
