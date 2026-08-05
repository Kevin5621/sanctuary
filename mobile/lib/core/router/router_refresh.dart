import 'dart:async';

import 'package:flutter/foundation.dart';

/// Menjembatani Stream (BLoC) ke Listenable yang dibutuhkan GoRouter,
/// sehingga setiap perubahan status autentikasi memicu evaluasi ulang redirect.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
