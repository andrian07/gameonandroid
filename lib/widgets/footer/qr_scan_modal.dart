import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/storage/sessionManager.dart';
import '../../models/userModel.dart';

void showQrScanModal(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xff1F1B2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: (screenWidth * 0.12).clamp(50.0, 80.0),
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "QR Code Kamu",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tunjukkan QR ini ke kasir untuk verifikasi atau pembayaran",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<UserModel?>(
                future: SessionManager.getUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final code = user != null
                      ? "GAMEON-USER-${user.id}"
                      : "GAMEON-GUEST";

                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: QrImageView(
                          data: code,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? "Guest",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Member ID: ${user?.id ?? '-'}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
