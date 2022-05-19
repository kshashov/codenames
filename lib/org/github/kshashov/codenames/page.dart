import 'package:codenames/org/github/kshashov/codenames/utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CodeNamesPage extends StatelessWidget {
  final Widget child;

  const CodeNamesPage({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: SafeArea(
          child: Column(children: [
        Expanded(child: child),
        Padding(
            padding: EdgeInsets.all(context.ui.paddingSmall),
            child: InkWell(
                child: const Text('github/kshashov/flutter-codenames'),
                onTap: () => launch('https://github.com/kshashov/flutter-codenames')))
      ])),
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
        style: TextStyle(fontSize: context.ui.fontSizeBig, fontWeight: FontWeight.bold),
      ),
        ));
  }
}
