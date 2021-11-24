import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stream_feed/stream_feed.dart';
import 'package:stream_feed_flutter_core/src/bloc/generic.dart';

class FeedProvider extends GenericFeedProvider<User, String, String, String> {
  const FeedProvider({
    Key? key,
    required GenericFeedBloc<User, String, String, String> bloc,
    required Widget child,
  }) : super(key: key, child: child, bloc: bloc);

  static of(BuildContext context) {
    return GenericFeedProvider<User, String, String, String>.of(context);
  }
}

class GenericFeedProvider<A, Ob, T, Or> extends InheritedWidget {
  const GenericFeedProvider({
    Key? key,
    required this.bloc,
    required Widget child,
  }) : super(key: key, child: child);

  factory GenericFeedProvider.of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<
        GenericFeedProvider<A, Ob, T, Or>>();
    assert(result != null,
        'No GenericFeedProvider<$A, $Ob, $T, $Or> found in context');
    return result!;
  }
  final GenericFeedBloc<A, Ob, T, Or> bloc;

  @override
  bool updateShouldNotify(GenericFeedProvider old) => bloc != old.bloc; //

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<GenericFeedBloc<A, Ob, T, Or>>('bloc', bloc));
  }
}
