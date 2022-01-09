import 'package:codenames/org/github/kshashov/codenames/responsive.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

extension PublishSubjectExtension<T> on PublishSubject<T> {
  PublishSubject<T> seeded(T value) {
    add(value);
    return this;
  }
}

class SeededStreamBuilder<T> extends StreamBuilder<T> {
  const SeededStreamBuilder({
    Key? key,
    BehaviorSubject<T>? stream,
    required AsyncWidgetBuilder<T> builder,
  }) : super(key: key, stream: stream, builder: builder);

  @override
  AsyncSnapshot<T> initial() {
    var value = (stream as BehaviorSubject).valueOrNull;
    return AsyncSnapshot<T>.withData(ConnectionState.none, value as T);
  }
}

class Badge extends StatelessWidget {
  final double top;
  final double right;
  final Widget child;
  final String? value;
  final Color? color;
  final double minSize;

  const Badge({Key? key, required this.child, this.value, this.color, this.top = 0, this.right = 0, this.minSize = 6})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          right: right,
          top: top,
          child: Container(
            padding: EdgeInsets.all(context.ui.padding * 0.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.ui.padding),
              color: color ?? Colors.green,
            ),
            constraints: BoxConstraints(
              minWidth: minSize,
              minHeight: minSize,
            ),
            child: value != null
                ? Text(
                    value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.ui.fontSize,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        )
      ],
    );
  }
}

extension BuildContextExtensions on BuildContext {
  ResponsiveUI get ui => ResponsiveUtils.ui(this);
}
