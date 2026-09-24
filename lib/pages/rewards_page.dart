import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/rewardModel.dart';
import '../widgets/appSnackbar.dart';
import '../widgets/footer/custom_bottom_nav.dart';
import 'reward_history_page.dart';

const _svgPath = "assets/images/icons/svg";
const _purple = Color(0xff7B2EFF);
const _pink = Color(0xffC44DFF);
const _gold = Color(0xffF6B91A);

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  int _point = 0;
  int? _selectedCategoryId; // null = "Semua"

  bool _loading = true;
  String? _loadError;
  List<RewardCategoryModel> _categories = [];
  List<RewardItemModel> _rewards = [];
  final Set<int> _redeemingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final user = await SessionManager.getUser();
    if (mounted) setState(() => _point = user?.point ?? 0);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _loadError = 'Sesi login tidak ditemukan, silakan login ulang.';
          _loading = false;
        });
        return;
      }

      final api = ApiService();
      final categoriesResponse = await api.postAuth(ApiUrl.rewardCategories, {}, token);
      final rewardsResponse = await api.postAuth(ApiUrl.rewards, {}, token);

      if (categoriesResponse['code'] == 200 && rewardsResponse['code'] == 200) {
        final categories = (categoriesResponse['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(RewardCategoryModel.fromJson)
            .toList();
        final rewards = (rewardsResponse['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(RewardItemModel.fromJson)
            .toList();

        if (!mounted) return;
        setState(() {
          _categories = categories;
          _rewards = rewards;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loadError = 'Gagal memuat daftar hadiah';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Server sedang gangguan, silakan coba lagi.';
        _loading = false;
      });
    }
  }

  List<RewardItemModel> get _visibleRewards {
    if (_selectedCategoryId == null) return _rewards;
    return _rewards.where((r) => r.categoryId == _selectedCategoryId).toList();
  }

  Future<void> _handleTukar(RewardItemModel item) async {
    if (item.pointCost > _point) {
      AppSnackbar.show(context, "Point kamu tidak cukup untuk hadiah ini", isError: true);
      return;
    }

    setState(() => _redeemingIds.add(item.id));

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (!mounted) return;
        AppSnackbar.show(context, "Sesi login tidak ditemukan, silakan login ulang", isError: true);
        return;
      }

      final response = await ApiService().postAuth(
        ApiUrl.redeemReward,
        {"reward_item_id": item.id},
        token,
      );

      if (response['code'] == 200) {
        final result = RewardRedemptionResult.fromJson(response['result']);

        // sinkronkan point lokal (dashboard/session) tanpa perlu fetch ulang customer_detail
        final cachedUser = await SessionManager.getUser();
        if (cachedUser != null) {
          final updated = cachedUser.copyWith(point: cachedUser.point - result.pointSpent);
          await SessionManager.saveUser(updated);
        }

        if (!mounted) return;
        setState(() => _point -= result.pointSpent);
        await _showRedeemSuccessDialog(result);
      } else {
        if (!mounted) return;
        AppSnackbar.show(context, response['result']?.toString() ?? "Gagal menukar point", isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context, 'Server sedang gangguan, silakan coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _redeemingIds.remove(item.id));
    }
  }

  Future<void> _showRedeemSuccessDialog(RewardRedemptionResult result) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xff1A1430),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_purple, _pink]),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                "${result.rewardName} berhasil ditukar!",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Tunjukkan kode ini ke staff/kasir untuk klaim hadiah kamu.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withOpacity(.5)),
                ),
                child: Text(
                  result.redeemCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ),
              if (result.benefitDescription != null) ...[
                const SizedBox(height: 12),
                Text(
                  result.benefitDescription!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11.5, height: 1.4),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("OKE, MENGERTI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090412),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/backgrounds/bg_tukar_point.png", fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(initialIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(.3), size: 40),
          const SizedBox(height: 12),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(.2)),
              ),
              child: const Text("Coba Lagi"),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        _buildPointCard(),
        const SizedBox(height: 20),
        _buildHowToCard(),
        const SizedBox(height: 22),
        _buildCategoryChips(),
        const SizedBox(height: 20),
        _buildPopularHeader(),
        const SizedBox(height: 12),
        _buildRewardGrid(),
        const SizedBox(height: 20),
        _buildPromoBanner(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: SvgPicture.asset(
                "$_svgPath/ic_arrow_back.svg",
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  "Tukar Point",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tukar point kamu dengan hadiah keren!",
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11.5),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardHistoryPage()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "$_svgPath/ic_history.svg",
                    width: 15,
                    height: 15,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Riwayat",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pink.withOpacity(.5), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            bottom: -10,
            child: Opacity(
              opacity: .95,
              child: Image.asset(
                "assets/images/icons/png/ic_chest_reward.png",
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Point Kamu",
                style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12.5),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatNumber(_point),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: _GCoinBadge(size: 26),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "1 Point = Rp 1",
                    style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    "$_svgPath/ic_info.svg",
                    width: 13,
                    height: 13,
                    colorFilter: ColorFilter.mode(Colors.white.withOpacity(.4), BlendMode.srcIn),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowToCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F).withOpacity(.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cara Tukar Point",
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HowToStep(
                  iconWidget: SvgPicture.asset(
                    "$_svgPath/ic_bag.svg",
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  title: "1. Pilih Hadiah",
                  description: "Pilih hadiah yang ingin kamu tukar",
                ),
              ),
              _StepArrow(),
              Expanded(
                child: _HowToStep(
                  iconWidget: const _GCoinBadge(size: 22),
                  title: "2. Tukar Point",
                  description: "Konfirmasi tukar point kamu",
                ),
              ),
              _StepArrow(),
              Expanded(
                child: _HowToStep(
                  iconWidget: SvgPicture.asset(
                    "$_svgPath/ic_gift.svg",
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  title: "3. Klaim Hadiah",
                  description: "Tunjukkan kode ke staff/kasir",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = <({int? id, String label, String? icon})>[
      (id: null, label: "Semua", icon: "ic_grid.svg"),
      for (final c in _categories) (id: c.id, label: c.name, icon: c.icon),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final selected = _selectedCategoryId == chip.id;
          return InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => setState(() => _selectedCategoryId = chip.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: selected ? const LinearGradient(colors: [_purple, _pink]) : null,
                color: selected ? null : Colors.white.withOpacity(.05),
                border: Border.all(
                  color: selected ? Colors.transparent : Colors.white.withOpacity(.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chip.icon != null)
                    SvgPicture.asset(
                      "$_svgPath/${chip.icon}",
                      width: 15,
                      height: 15,
                      colorFilter: ColorFilter.mode(
                        selected ? Colors.white : Colors.white70,
                        BlendMode.srcIn,
                      ),
                    ),
                  const SizedBox(width: 7),
                  Text(
                    chip.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularHeader() {
    return const Text(
      "Pilih Hadiah",
      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRewardGrid() {
    if (_visibleRewards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            "Belum ada hadiah di kategori ini",
            style: TextStyle(color: Colors.white.withOpacity(.4)),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in _visibleRewards) ...[
          _RewardCard(
            item: item,
            isRedeeming: _redeemingIds.contains(item.id),
            onTukar: () => _handleTukar(item),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Image.asset("assets/images/icons/png/ic_promo_ticket.png", width: 44, height: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Semakin banyak point, semakin banyak hadiah!",
                  style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  "Kumpulkan point dari setiap transaksi dan event menarik.",
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
    }
    return buffer.toString();
  }
}

class _GCoinBadge extends StatelessWidget {
  final double size;

  const _GCoinBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xffFFD873), _gold]),
      ),
      child: Text(
        "G",
        style: TextStyle(
          color: Colors.black.withOpacity(.65),
          fontSize: size * .55,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HowToStep extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String description;

  const _HowToStep({required this.iconWidget, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _purple.withOpacity(.18),
            border: Border.all(color: _purple.withOpacity(.4)),
          ),
          child: iconWidget,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Text(
          description,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 9.5, height: 1.3),
        ),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SvgPicture.asset(
        "$_svgPath/ic_chevron_right.svg",
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(Colors.white.withOpacity(.25), BlendMode.srcIn),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final RewardItemModel item;
  final bool isRedeeming;
  final VoidCallback onTukar;

  const _RewardCard({required this.item, required this.isRedeeming, required this.onTukar});

  @override
  Widget build(BuildContext context) {
    final imageFile = item.image;
    final imagePath = (imageFile != null && imageFile.isNotEmpty)
        ? "assets/images/illustrations/$imageFile"
        : "assets/images/icons/png/ic_chest_reward.png";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(imagePath, width: 68, height: 68, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.subtitle?.isNotEmpty == true ? item.subtitle! : item.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatNumber(item.pointCost),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    const _GCoinBadge(size: 15),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isRedeeming ? null : onTukar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isRedeeming ? Colors.white24 : _gold, width: 1.2),
              ),
              child: isRedeeming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
                    )
                  : const Text(
                      "Tukar",
                      style: TextStyle(color: _gold, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final posFromRight = digits.length - i;
      buffer.write(digits[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
    }
    return buffer.toString();
  }
}
