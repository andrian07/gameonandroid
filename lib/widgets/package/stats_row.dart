import 'package:flutter/material.dart';

import '../../models/userModel.dart';
import '../../pages/game_list_page.dart';
import '../../pages/rewards_page.dart';
import '../header/sisa_waktu_modal.dart';

/// Panel ringkas 3 metrik akun: Point, Waktu Disimpan, Saldo.
/// Satu kartu utuh dengan 3 segmen bergaris pemisah - tiap segmen bisa ditekan
/// menuju halaman terkait.
class StatsRow extends StatelessWidget {
  final UserModel? user;

  const StatsRow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff17182A), Color(0xff101120)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Segment(
                  iconPath: "assets/images/icons/ic_point.png",
                  value: _formatNumber(user?.point ?? 0),
                  label: "Point",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardsPage()),
                  ),
                ),
              ),
              _divider(),
              Expanded(
                child: _Segment(
                  iconPath: "assets/images/icons/ic_time.png",
                  value: _formatDuration(user?.timeRemainingMinutes ?? 0),
                  label: "Waktu Disimpan",
                  onTap: () => showSisaWaktuModal(context),
                ),
              ),
              _divider(),
              Expanded(
                child: _Segment(
                  iconPath: "assets/images/icons/ic_game.png",
                  value: "$gameListCount+",
                  label: "Game Tersedia",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameListPage()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 14),
        color: Colors.white.withOpacity(.07),
      );

  String _formatNumber(int value) => _group(value.toString());

  String _group(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
    }
    return buffer.toString();
  }

  /// Total waktu tersimpan dalam format jam:menit, mis. 1559 menit -> "25:59".
  String _formatDuration(int totalMinutes) {
    final safe = totalMinutes < 0 ? 0 : totalMinutes;
    final hours = safe ~/ 60;
    final minutes = safe % 60;
    return "$hours:${minutes.toString().padLeft(2, '0')}";
  }
}

class _Segment extends StatelessWidget {
  final String iconPath;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _Segment({
    required this.iconPath,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(iconPath, width: 32, height: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(.4), size: 13),
                      ],
                    ),
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
