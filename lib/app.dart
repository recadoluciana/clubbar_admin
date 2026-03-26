import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'modules/auth/login_page.dart';
import 'modules/dashboard/dashboard_page.dart';

class ClubbarAdminApp extends StatelessWidget {
  const ClubbarAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clubbar Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const SplashDeciderPage(),
    );
  }
}

class SplashDeciderPage extends StatefulWidget {
  const SplashDeciderPage({super.key});

  @override
  State<SplashDeciderPage> createState() => _SplashDeciderPageState();
}

class _SplashDeciderPageState extends State<SplashDeciderPage> {
  bool _carregando = true;
  bool _temToken = false;

  @override
  void initState() {
    super.initState();
    _verificarToken();
  }

  Future<void> _verificarToken() async {
    final token = await StorageService.getToken();

    if (!mounted) return;

    setState(() {
      _temToken = token != null && token.isNotEmpty;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_temToken) {
      return const DashboardPage();
    }

    return const LoginPage();
  }
}