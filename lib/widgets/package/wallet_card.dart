import 'package:flutter/material.dart';

import '../../models/userModel.dart';
import '../../pages/transaction_list.dart';
import '../header/top_up_modal.dart';

/// Kartu saldo utama di dashboard. Background bergambar (bg_wallet_card.png)
/// + overlay teks saldo, ajakan top up, dan tombol Top Up.
class WalletCard extends StatelessWidget {
  final UserModel? user;

  const WalletCard({super.key, required this.user});

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
    }
    return "Rp$buffer";
  }

  @override
  Widget build(BuildContext context) {
    final saldo = _formatRupiah((user?.saldo ?? 0).toInt());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff7B2EFF).withOpacity(.30),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/backgrounds/bg_wallet_card.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xff17092E).withOpacity(.82),
                        const Color(0xff17092E).withOpacity(.15),
                        const Color(0xff17092E).withOpacity(.0),
                      ],
                      stops: const [0, .55, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "GOOD GAME",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      "BETTER FRIENDS",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.45),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                "assets/images/icons/png/ic_wallet.png",
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                "WALLET",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Saldo Wallet",
                            style: TextStyle(
                              color: Colors.white.withOpacity(.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              saldo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TransactionListPage()),
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Main lebih lama, lebih seru!",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(.2)),
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                      color: Colors.white, size: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TopUpButton(onTap: () => showTopUpModal(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopUpButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TopUpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xffFF4FD8), Color(0xff8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffFF4FD8).withOpacity(.4),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 22),
              SizedBox(height: 2),
              Text(
                "Top Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
