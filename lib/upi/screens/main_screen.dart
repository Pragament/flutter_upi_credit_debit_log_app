import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:quick_actions/quick_actions.dart';
import 'bottom_navbar.dart';

// Providers for dependencies
final quickActionsProvider = Provider<QuickActions>((ref) => QuickActions());
final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read dependencies from providers
    final quickActions = ref.read(quickActionsProvider);
    final auth = ref.read(localAuthProvider);

    return KBottom(quickActions: quickActions);
  }
}
