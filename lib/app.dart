import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/login_page.dart';
import 'modules/superadmin/superadmin_dashboard_page.dart';

class ClubbarAdminApp extends StatelessWidget {
  const ClubbarAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Clubbar Admin',
    theme: AppTheme.light,
    home: const _AdminSession(),
  );
}

class _AdminSession extends StatelessWidget {
  const _AdminSession();

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: StorageService.getToken(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return snapshot.data?.isNotEmpty == true
          ? const SuperAdminDashboardPage()
          : const LoginPage();
    },
  );
}
