import 'package:flutter/material.dart';

import '../../models/userModel.dart';
import 'top_up_modal.dart';

class GreetingCard extends StatelessWidget {
  final UserModel? user;

  const GreetingCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.name.split(" ").first ?? "Player";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff171826),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.15), width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset("assets/images/_archive/avatar.png", fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hai, $name!",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Selamat datang kembali",
                  style: TextStyle(
                    color: Colors.white.withOpacity(.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showTopUpModal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatRupiah((user?.saldo ?? 0).toInt()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
    }
    return "Rp $buffer";
  }
}
