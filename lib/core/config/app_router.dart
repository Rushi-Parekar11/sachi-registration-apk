import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

import '../../features/patients/presentation/patient_registration_screen.dart';
import '../../features/patients/domain/patient.dart';
import '../../shared/widgets/main_scaffold.dart';



final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          GoRoute(
            path: '/patient-registration',
            builder: (context, state) {
              final patient = state.extra as Patient?;
              return PatientRegistrationScreen(patient: patient);
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) =>
                const Center(child: Text('Settings (TBD)')),
          ),
        ],
      ),
    ],
  );
});
