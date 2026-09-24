import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api/apiService.dart';
import '../../core/api/apiUrl.dart';
import '../../core/storage/sessionManager.dart';

/// Popup wajib diisi saat dashboard dibuka dan PIN transaksi belum pernah
/// disimpan di backend. Tidak bisa ditutup dengan tap di luar atau tombol
/// back - hanya bisa lolos dengan menyimpan PIN yang valid.
Future<bool> showPinSetupModal(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: _PinSetupDialog(dismissible: false),
    ),
  );
  return saved ?? false;
}

/// Popup ubah PIN transaksi dari halaman profil - PIN sudah pernah diisi
/// sebelumnya, jadi boleh dibatalkan/ditutup kapan saja.
Future<bool> showUpdatePinModal(BuildContext context) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _PinSetupDialog(dismissible: true),
  );
  return saved ?? false;
}

class _PinSetupDialog extends StatefulWidget {
  final bool dismissible;

  const _PinSetupDialog({required this.dismissible});

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  // PIN lama cuma relevan saat UBAH PIN (widget.dismissible == true), yaitu
  // PIN sudah pernah dibuat sebelumnya. Saat SETUP PIN pertama kali belum
  // ada PIN lama untuk diverifikasi, jadi field ini tidak ditampilkan/dipakai.
  final oldPinController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  String? errorText;
  bool isSaving = false;

  @override
  void dispose() {
    oldPinController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final oldPin = oldPinController.text.trim();
    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (widget.dismissible && oldPin.length != 6) {
      setState(() => errorText = "PIN lama harus 6 digit angka");
      return;
    }

    if (pin.length != 6 || confirmPin.length != 6) {
      setState(() => errorText = "PIN harus 6 digit angka");
      return;
    }

    if (pin != confirmPin) {
      setState(() => errorText = "Konfirmasi PIN tidak sama");
      return;
    }

    if (widget.dismissible && oldPin == pin) {
      setState(() => errorText = "PIN baru tidak boleh sama dengan PIN lama");
      return;
    }

    setState(() {
      errorText = null;
      isSaving = true;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => errorText = "Sesi login tidak ditemukan, silakan login ulang");
        return;
      }

      final response = await ApiService().postAuth(
        ApiUrl.updatePin,
        {
          "pin": pin,
          // Dikirim hanya saat ubah PIN supaya backend bisa verifikasi PIN
          // lama sebelum mengganti - sejalan dengan alur "Ubah Password"
          // (current_password/new_password) di halaman yang sama.
          if (widget.dismissible) "current_pin": oldPin,
        },
        token,
      );

      if (response["code"] == 200) {
        // Perbarui cache user lokal supaya status "sudah punya PIN" langsung
        // konsisten tanpa harus fetch ulang customer_detail.
        final cachedUser = await SessionManager.getUser();
        if (cachedUser != null) {
          await SessionManager.saveUser(cachedUser.copyWith(hasPin: true));
        }

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        setState(() => errorText = response["result"]?.toString() ?? "Gagal menyimpan PIN");
      }
    } catch (e) {
      setState(() => errorText = "Server sedang gangguan, silakan coba lagi.");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.dismissible)
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.1)),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white70, size: 15),
                  ),
                ),
              ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                ),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              widget.dismissible ? "Ubah PIN Transaksi" : "Buat PIN Transaksi",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "PIN digunakan untuk konfirmasi setiap transaksi di GameOn",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (widget.dismissible) ...[
              _pinField(oldPinController, "PIN Lama (6 digit)"),
              const SizedBox(height: 14),
            ],
            _pinField(pinController, widget.dismissible ? "PIN Baru (6 digit)" : "Buat PIN (6 digit)"),
            const SizedBox(height: 14),
            _pinField(confirmPinController, "Konfirmasi PIN"),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  backgroundColor: Colors.transparent,
                  shadowColor: const Color(0xffA64DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: isSaving ? null : _handleSave,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xff6C3BFF), Color(0xffC44DFF)],
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "SIMPAN PIN",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        letterSpacing: 10,
        fontWeight: FontWeight.bold,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        counterText: "",
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 0),
        filled: true,
        fillColor: Colors.white.withOpacity(.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
