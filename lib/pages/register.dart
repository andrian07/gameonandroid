import 'dart:math';

import 'package:flutter/material.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/userModel.dart';
import '../widgets/appSnackbar.dart';
import 'dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateIdNumber() {
    final random = Random();
    return List.generate(10, (_) => random.nextInt(10)).join();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      AppSnackbar.show(context, 'Semua field wajib diisi.', isError: true);
      return;
    }

    if (password != confirmPassword) {
      AppSnackbar.show(context, 'Konfirmasi password tidak sama.', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService().post(ApiUrl.register, {
        "customer_phone": phone,
        "customer_pass": password,
        "name": name,
        "id_number": _generateIdNumber(),
        "address": "",
        "email": email,
      });

      if (response["code"] == 200) {
        final user = UserModel.fromJson(response["result"]);
        await SessionManager.saveUser(user);

        final token = response["token"]?.toString();
        if (token != null) {
          await SessionManager.saveToken(token);
        }

        if (!mounted) return;
        AppSnackbar.show(context, "Pendaftaran berhasil, selamat bergabung!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        if (!mounted) return;
        AppSnackbar.show(
          context,
          response["result"]?.toString() ?? "Pendaftaran gagal",
          isError: true,
        );
      }
    } catch (e) {
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

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffixIcon}) {
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
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: const BorderSide(color: Color(0xffC44DFF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0B0620),
      body: SizedBox.expand(
        child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgrounds/bg_login.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/logo/logo.png",
                        height: 150,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PLAY MORE, BE A MEMBER",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Daftar Akun",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Buat akun untuk mulai bermain dan nikmati semua fitur member.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.6),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Nama Lengkap", Icons.person_outline_rounded),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("No. Handphone", Icons.phone_outlined),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration("Email", Icons.email_outlined),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
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
                                setState(() => hidePassword = !hidePassword);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: confirmPasswordController,
                          obscureText: hideConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: _decoration(
                            "Konfirmasi Password",
                            Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              icon: Icon(
                                hideConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white54,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(
                                  () => hideConfirmPassword = !hideConfirmPassword,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

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
                            onPressed: isLoading ? null : register,
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
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Daftar Sekarang",
                                            style: TextStyle(
                                              fontSize: 16,
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
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Sudah punya akun? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(.75),
                                fontSize: 13.5,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.maybePop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Login di sini",
                                style: TextStyle(
                                  color: Color(0xffFF4FD8),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 4,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(.25),
                      border: Border.all(color: const Color(0xffFF4FD8), width: 1.4),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
