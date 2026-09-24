import 'package:flutter/material.dart';
import 'register.dart';
import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../models/userModel.dart';
import '../core/storage/sessionManager.dart';
import '../widgets/appSnackbar.dart';
import '../services/push_service.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userphoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  Future<void> login() async {
    final phone = userphoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      AppSnackbar.show(
        context,
        'No HP dan password wajib diisi.',
        isError: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService().post(ApiUrl.login, {
        "customer_phone": phone,
        "customer_pass": password,
      });

      if (response["code"] == 200) {
        final user = UserModel.fromJson(response["result"]);
        await SessionManager.saveUser(user);

        final token = response["token"]?.toString();
        if (token != null) {
          await SessionManager.saveToken(token);
        }

        // Daftarkan FCM token perangkat ke server untuk akun ini (push notif).
        // Kegagalan push (mis. di web / Firebase belum init) tidak boleh
        // membatalkan login yang sebenarnya sudah berhasil.
        try {
          PushService.instance.registerAfterLogin();
        } catch (e) {
          debugPrint('[LOGIN] registerAfterLogin dilewati: $e');
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        if (!mounted) return;
        AppSnackbar.show(
          context,
          response["result"]?.toString() ?? "No HP atau password salah",
          isError: true,
        );
      }
    } catch (e, st) {
      debugPrint('[LOGIN] error: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        'Server sedang gangguan, silakan coba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(
    String hint,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide(color: Colors.white.withOpacity(.1)),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(.4)),
      prefixIcon: Icon(icon, color: Colors.white70, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xff1B1440).withOpacity(.55),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(color: Color(0xffC44DFF)),
      ),
    );
  }

  Widget _divider() =>
      Expanded(child: Divider(color: Colors.white.withOpacity(.2), height: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0620),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgrounds/bg_login.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: h * 0.03),
                        Image.asset(
                          "assets/images/logo/logo.png",
                          height: h * 0.26,
                        ),
                        SizedBox(height: h * 0.008),
                        Text(
                          "PLAY MORE, BE A MEMBER",
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: h * 0.035),

                        TextField(
                          controller: userphoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration(
                            "Member ID / No. HP",
                            Icons.person_outline_rounded,
                          ),
                        ),
                        SizedBox(height: h * 0.016),

                        TextField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration(
                            "Password",
                            Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                  () => hidePassword = !hidePassword,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.012),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Forgot Password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Lupa Password?",
                              style: TextStyle(
                                color: Color(0xffFF4FD8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.022),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 10,
                              backgroundColor: Colors.transparent,
                              shadowColor: const Color(0xffFF2E9B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: isLoading ? null : login,
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xffFF3FA5),
                                    Color(0xffE01E8C),
                                  ],
                                ),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Login",
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.022),

                        Row(
                          children: [
                            _divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                "atau",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.6),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            _divider(),
                          ],
                        ),
                        SizedBox(height: h * 0.02),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Belum punya akun? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.75),
                                fontSize: 14.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Daftar Sekarang",
                                style: TextStyle(
                                  color: Color(0xffFF4FD8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: h * 0.08),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
