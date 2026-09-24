import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pages/splash.dart';
import 'pages/login.dart'; // sesuaikan
import 'pages/dashboard.dart'; // sesuaikan
import '../../models/userModel.dart';
import '../../core/storage/sessionManager.dart';
import 'core/navigation/appRouteObserver.dart';
import 'services/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase belum dikonfigurasi untuk web (firebase_options.dart hanya
    // Android/iOS), jadi di web dilewati - app tetap jalan tanpa push.
    if (!kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      debugPrint('[PUSH] Firebase initialized');
      // Jangan blokir startup - inisialisasi push jalan di belakang.
      PushService.instance.init();
    }
  } catch (e, s) {
    // App tetap jalan walau Firebase gagal init (mis. tanpa Google Play Services).
    debugPrint('[PUSH] Firebase init FAILED: $e\n$s');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    // Contoh jika SessionManager menyimpan UserModel
    UserModel? user = await SessionManager.getUser();

    if (user != null) {
      return const DashboardPage();
    }

    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "GAMEON",
      navigatorKey: navigatorKey,
      theme: ThemeData(useMaterial3: true, fontFamily: "Poppins"),
      navigatorObservers: [appRouteObserver],
      // Layout-nya didesain untuk lebar HP. Di layar lebar (tablet/web/desktop)
      // konten dibatasi lebar maksimum & ditengahkan, bukan direntang penuh -
      // supaya semua halaman tetap proporsional di berbagai ukuran layar.
      builder: (context, child) {
        return Container(
          color: const Color(0xff090A17),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashPage();
          }

          return snapshot.data ?? const LoginPage();
        },
      ),
    );
  }
}
