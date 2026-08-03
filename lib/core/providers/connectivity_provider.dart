import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the current connectivity status
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// A derived provider that just returns a boolean: true if online, false if offline
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityProvider);
  
  return connectivityState.when(
    data: (results) {
      if (results.contains(ConnectivityResult.none)) {
        return false;
      }
      return results.isNotEmpty;
    },
    loading: () => true, // Assume online while checking
    error: (_, __) => true, // Assume online if error checking
  );
});
