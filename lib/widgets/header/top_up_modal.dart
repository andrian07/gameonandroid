import 'package:flutter/material.dart';

import '../../core/api/apiService.dart';
import '../../core/api/apiUrl.dart';
import '../../core/storage/sessionManager.dart';
import '../../models/topupBonusModel.dart';
import '../appSnackbar.dart';
import '../result_banner.dart';

enum _PaymentMethod { cash, transfer }

class _NominalOption {
  final int amount;
  final String? badge;

  const _NominalOption(this.amount, {this.badge});
}

const _nominalOptions = [
  _NominalOption(10000),
  _NominalOption(50000),
  _NominalOption(100000, badge: "Bonus 5%"),
  _NominalOption(150000),
  _NominalOption(200000),
];

void showTopUpModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _TopUpModalSheet(),
  );
}

class _TopUpModalSheet extends StatefulWidget {
  const _TopUpModalSheet();

  @override
  State<_TopUpModalSheet> createState() => _TopUpModalSheetState();
}

class _TopUpModalSheetState extends State<_TopUpModalSheet> {
  // Transfer belum bisa dipakai untuk saat ini (lihat _PaymentOption di bawah) - Cash jadi satu-satunya
  // pilihan yang valid, jadi langsung dipilihkan dari awal supaya user tidak perlu tap apa-apa lagi.
  _PaymentMethod? _method = _PaymentMethod.cash;
  int? _nominal;
  bool _submitting = false;

  // Promo "Extra Saldo" yang lagi aktif (kalau ada) - lihat
  // docs/topup_bonus_setting.sql. Best-effort: null kalau tidak ada promo
  // aktif atau endpoint-nya gagal, banner-nya cukup disembunyikan saja.
  TopupBonusModel? _bonus;

  @override
  void initState() {
    super.initState();
    _loadBonus();
  }

  Future<void> _loadBonus() async {
    try {
      final token = await SessionManager.getToken();
      if (token == null) return;
      final response =
          await ApiService().postAuth(ApiUrl.topupBonusInfo, {}, token);
      if (response is Map && response['code'] == 200 && response['result'] is Map) {
        final bonus =
            TopupBonusModel.fromJson(Map<String, dynamic>.from(response['result']));
        if (mounted) setState(() => _bonus = bonus);
      }
    } catch (_) {
      // Diamkan - banner promo memang opsional, tidak boleh mengganggu alur top up.
    }
  }

  bool get _isValid => _method != null && _nominal != null;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff231D3D), Color(0xff15121F)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: const Color(0xff9D4DFF).withOpacity(.25)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff7B2EFF).withOpacity(.2),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: (screenWidth * 0.12).clamp(44.0, 64.0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff7B2EFF).withOpacity(.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Top Up Saldo",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            "Isi saldo GameOn kamu",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_bonus != null) ...[
                  _buildBonusBanner(_bonus!),
                  const SizedBox(height: 14),
                ],
                _sectionLabel(Icons.payments_rounded, "Pilih Pembayaran"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PaymentOption(
                        icon: Icons.payments_outlined,
                        label: "Cash",
                        description: "Bayar tunai di kasir",
                        selected: _method == _PaymentMethod.cash,
                        onTap: () =>
                            setState(() => _method = _PaymentMethod.cash),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PaymentOption(
                        icon: Icons.account_balance_outlined,
                        label: "Transfer",
                        description: "Belum tersedia",
                        selected: false,
                        disabled: true,
                        onTap: () => AppSnackbar.show(
                          context,
                          "Transfer belum bisa digunakan untuk saat ini, silakan pakai Cash dulu.",
                          isError: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _sectionLabel(Icons.confirmation_number_rounded, "Nominal"),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _nominalOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    final option = _nominalOptions[index];
                    return _NominalChip(
                      option: option,
                      selected: _nominal == option.amount,
                      onTap: () => setState(() => _nominal = option.amount),
                    );
                  },
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isValid
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildSummary(),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: _isValid
                          ? const LinearGradient(
                              colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                            )
                          : null,
                      color: _isValid ? null : Colors.white.withOpacity(.06),
                      boxShadow: _isValid
                          ? [
                              BoxShadow(
                                color: const Color(0xff7B2EFF).withOpacity(.4),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: (_isValid && !_submitting) ? _handleDeposit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white30,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "AJUKAN TOP UP",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: .5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: _isValid ? Colors.white : Colors.white30,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeposit() async {
    setState(() => _submitting = true);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (!mounted) return;
        AppSnackbar.show(context, 'Sesi login tidak ditemukan, silakan login ulang', isError: true);
        return;
      }

      final response = await ApiService().postAuth(ApiUrl.topup, {
        "amount": _nominal,
        "payment_method": _method == _PaymentMethod.cash ? "Cash" : "Transfer",
      }, token);

      if (response["code"] == 200) {
        if (!mounted) return;
        final rootContext = Navigator.of(context, rootNavigator: true).context;
        Navigator.pop(context);
        ResultBanner.show(
          rootContext,
          success: true,
          title: "Top Up Terkirim",
          message:
              "Permintaan top up ${_formatRupiah(_nominal!)} menunggu konfirmasi kasir di GameOn.",
        );
      } else {
        if (!mounted) return;
        ResultBanner.show(
          context,
          success: false,
          title: "Top Up Gagal",
          message: response["result"]?.toString() ??
              "Gagal mengajukan top up, coba lagi.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      ResultBanner.show(
        context,
        success: false,
        title: "Top Up Gagal",
        message: "Server sedang gangguan, silakan coba lagi.",
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildBonusBanner(TopupBonusModel bonus) {
    final minText = bonus.minTopupAmount > 0
        ? " min. ${_formatRupiah(bonus.minTopupAmount)}"
        : "";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF6B91A).withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffF6B91A).withOpacity(.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.card_giftcard_rounded,
              color: Color(0xffF6B91A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Extra Saldo ${_formatRupiah(bonus.bonusAmount)}$minText",
                  style: const TextStyle(
                    color: Color(0xffF6B91A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (bonus.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    bonus.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.65),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Top Up",
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(_nominal!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_bonus != null && _bonus!.eligibleFor(_nominal!)) ...[
                  const SizedBox(height: 2),
                  Text(
                    "+ Bonus ${_formatRupiah(_bonus!.bonusAmount)} = saldo ${_formatRupiah(_nominal! + _bonus!.bonusAmount)}",
                    style: const TextStyle(
                      color: Color(0xffF6B91A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff2ED573).withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _method == _PaymentMethod.cash
                      ? Icons.payments_outlined
                      : Icons.account_balance_outlined,
                  color: const Color(0xff2ED573),
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  _method == _PaymentMethod.cash ? "Cash" : "Transfer",
                  style: const TextStyle(
                    color: Color(0xff2ED573),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xffA855F7), size: 14),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xffA855F7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = disabled
        ? Colors.white24
        : (selected ? Colors.white : Colors.white60);
    final labelColor = disabled
        ? Colors.white38
        : (selected ? Colors.white : Colors.white70);
    final descriptionColor = disabled
        ? Colors.white24
        : (selected ? Colors.white.withOpacity(.75) : Colors.white38);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff7B2EFF), Color(0xff6524D9)],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(disabled ? .02 : .04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(.1),
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: descriptionColor,
                          fontSize: 9.5,
                          fontStyle: disabled ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (selected)
              const Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NominalChip extends StatelessWidget {
  final _NominalOption option;
  final bool selected;
  final VoidCallback onTap;

  const _NominalChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff7B2EFF), Color(0xff6524D9)],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(.1),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffF6B91A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        option.badge!,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    _formatRupiah(option.amount),
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
