import 'dart:async';
import 'package:flutter/foundation.dart';

/// Converts a [Stream] into a [Listenable].
/// 
/// Helpful for `GoRouter`'s `refreshListenable` when working with 
/// Supabase's `onAuthStateChange` stream.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
