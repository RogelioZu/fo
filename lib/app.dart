import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: reemplazar con MaterialApp.router + GoRouter en Paso 9
    return MaterialApp(
      title: 'Finding Out',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(
          child: Text('Finding Out — Theme loaded ✓'),
        ),
      ),
    );
  }
}
