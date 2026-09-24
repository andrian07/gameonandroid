import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/rewardModel.dart';

const _purple = Color(0xff7B2EFF);
const _gold = Color(0xffF6B91A);

// Daftar hadiah yang sudah ditukar member (dari reward_redemption di gameon) - diakses lewat tombol
// "Riwayat" di halaman Tukar Point.
class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  bool _loading = true;
  String? _error;
  List<RewardRedemptionModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() {
          _error = 'Sesi login tidak ditemukan, silakan login ulang.';
          _loading = false;
        });
        return;
      }

      final response = await ApiService().postAuth(ApiUrl.rewardRedemptions, {}, token);
      if (response['code'] == 200 && response['result'] is List) {
        final items = (response['result'] as List)
            .whereType<Map<String, dynamic>>()
            .map(RewardRedemptionModel.fromJson)
            .toList();
        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = response['result']?.toString() ?? 'Gagal memuat riwayat';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Server sedang gangguan, silakan coba lagi.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090412),
      body: SafeArea(
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
                "assets/images/icons/svg/ic_arrow_back.svg",
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            "Riwayat Tukar Point",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(.3), size: 40),
          const SizedBox(height: 12),
          Text(
            _error!,
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

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.card_giftcard_rounded, color: Colors.white.withOpacity(.25), size: 40),
          const SizedBox(height: 12),
          Text(
            "Belum ada hadiah yang ditukar",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _RedemptionTile(data: _items[index]),
    );
  }
}

class _RedemptionTile extends StatelessWidget {
  final RewardRedemptionModel data;

  const _RedemptionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final imageFile = data.image;
    final imagePath = (imageFile != null && imageFile.isNotEmpty)
        ? "assets/images/illustrations/$imageFile"
        : "assets/images/icons/png/ic_chest_reward.png";

    final isClaimed = data.status == 'Claimed';
    final isCancelled = data.status == 'Cancelled';
    final statusColor = isCancelled
        ? const Color(0xffFF5A71)
        : (isClaimed ? const Color(0xff2ED573) : _gold);
    final statusLabel = isCancelled ? "Dibatalkan" : (isClaimed ? "Sudah Diklaim" : "Belum Diklaim");

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1B1836), Color(0xff141227)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(imagePath, width: 52, height: 52, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.rewardName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDate(data.createdAt),
                      style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _purple.withOpacity(.3)),
            ),
            child: Text(
              data.redeemCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final time =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return "${date.day} ${months[date.month - 1]} ${date.year}, $time";
  }
}
