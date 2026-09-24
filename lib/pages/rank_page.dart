// CATATAN: fitur "Cari Lawan" (rank/room PvP) untuk sementara DINONAKTIFKAN.
// Halaman ini sengaja tidak dihapus - seluruh implementasinya di bawah tetap
// disimpan supaya bisa diaktifkan lagi nanti. Yang tampil ke user hanya
// [RankPage.build] yang memunculkan pesan "fitur belum tersedia".
// ignore_for_file: unused_element, unused_field, unused_import, unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/storage/sessionManager.dart';
import '../widgets/appSnackbar.dart';

enum _Game { efootball, fifa }

extension on _Game {
  String get label => this == _Game.efootball ? "eFootball" : "FIFA";
  String get bgAsset => this == _Game.efootball
      ? "assets/images/games/gm_efootball.png"
      : "assets/images/games/gm_fifa.png";
}

class _Room {
  final String hostName;
  final String hostRank;
  final _Game game;
  final int stake; // 0 = tanpa taruhan
  final String unit;
  final String timeAgo;
  final String avatarAsset;
  final int slotsFilled;
  final int slotsTotal;

  const _Room({
    required this.hostName,
    required this.hostRank,
    required this.game,
    required this.stake,
    required this.unit,
    required this.timeAgo,
    required this.avatarAsset,
    this.slotsFilled = 1,
    this.slotsTotal = 2,
  });

  String get stakeLabel => stake == 0 ? "Tanpa taruhan" : "$stake pt";
}

const _openRooms = [
  _Room(
    hostName: "Rizky",
    hostRank: "Platinum II",
    game: _Game.efootball,
    stake: 50,
    unit: "03",
    timeAgo: "3 mnt lalu",
    avatarAsset: "assets/images/avatars/av_slot_2.png",
  ),
  _Room(
    hostName: "Bagas",
    hostRank: "Gold I",
    game: _Game.fifa,
    stake: 25,
    unit: "11",
    timeAgo: "6 mnt lalu",
    avatarAsset: "assets/images/avatars/av_slot_3.png",
  ),
  _Room(
    hostName: "Dimas",
    hostRank: "Diamond IV",
    game: _Game.efootball,
    stake: 0,
    unit: "07",
    timeAgo: "9 mnt lalu",
    avatarAsset: "assets/images/avatars/av_slot_4.png",
  ),
  _Room(
    hostName: "Fajar",
    hostRank: "Silver III",
    game: _Game.fifa,
    stake: 25,
    unit: "14",
    timeAgo: "12 mnt lalu",
    avatarAsset: "assets/images/avatars/av_slot_1.png",
  ),
];

const _pink = Color(0xffFF3E9E);
const _purple = Color(0xff7B2EFF);
const _gold = Color(0xffF6B91A);

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  String? _filterGame;
  int? _point;
  _Room? _myRoom;

  @override
  void initState() {
    super.initState();
    _loadPoint();
  }

  Future<void> _loadPoint() async {
    final user = await SessionManager.getUser();
    if (mounted) setState(() => _point = user?.point ?? 0);
  }

  List<_Room> get _visibleRooms {
    switch (_filterGame) {
      case "eFootball":
        return _openRooms.where((r) => r.game == _Game.efootball).toList();
      case "FIFA":
        return _openRooms.where((r) => r.game == _Game.fifa).toList();
      case "Tanpa taruhan":
        return _openRooms.where((r) => r.stake == 0).toList();
      default:
        return _openRooms;
    }
  }

  Future<void> _openCreateRoomSheet() async {
    final room = await showModalBottomSheet<_Room>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateRoomSheet(availablePoint: _point ?? 0),
    );

    if (room != null && mounted) {
      setState(() => _myRoom = room);
      AppSnackbar.show(context, "Room berhasil dibuat, menunggu lawan bergabung");
    }
  }

  void _closeMyRoom() {
    setState(() => _myRoom = null);
    AppSnackbar.show(context, "Room ditutup");
  }

  void _handleGabung(_Room room) {
    final point = _point ?? 0;
    if (room.stake > point) {
      AppSnackbar.show(context, "Poin kamu tidak cukup untuk gabung room ini", isError: true);
      return;
    }
    AppSnackbar.show(
      context,
      "Berhasil gabung room ${room.hostName}, tunjukkan ke kasir untuk konfirmasi unit & durasi",
    );
  }

  // Fitur "Cari Lawan" sementara dinonaktifkan - tampilkan placeholder.
  // Implementasi asli (_buildHeader, _RoomCard, _CreateRoomSheet, dll) tetap
  // disimpan di file ini untuk diaktifkan kembali nanti.
  @override
  Widget build(BuildContext context) {
    return const _RankComingSoonView();
  }

  Widget _buildRankBoard(BuildContext context) {
    final pointText = _point == null ? "-" : _formatNumber(_point!);

    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _buildCheckInBar(),
                  const SizedBox(height: 16),
                  _myRoom == null ? _buildNoRoomCard() : _buildMyRoomCard(_myRoom!),
                  const SizedBox(height: 26),
                  _buildBoardHeader(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 14),
                  for (final r in _visibleRooms) ...[
                    _RoomCard(room: r, onGabung: () => _handleGabung(r)),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 10),
                  _buildHowToCard(),
                ],
              ),
            ),
            _buildFooter(pointText),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Text(
              "Cari Lawan",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.refresh_rounded,
            onTap: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff171826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xff2ED573), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.white70),
                children: [
                  TextSpan(text: "Check-in: "),
                  TextSpan(
                    text: "GameOn Pusat",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: " · Unit 07"),
                ],
              ),
            ),
          ),
          const Text("18 pemain", style: TextStyle(color: Colors.white38, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildNoRoomCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(.12), width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_purple, _pink]),
            ),
            child: const Icon(Icons.meeting_room_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 14),
          const Text(
            "Belum ada room aktif",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Buat room, pilih game & pertaruhkan point untuk mulai mencari lawan",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: _PillButton(
              label: "Buat Room",
              onTap: _openCreateRoomSheet,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRoomCard(_Room room) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff130E1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _pink.withOpacity(.6), width: 1.4),
        boxShadow: [
          BoxShadow(color: _pink.withOpacity(.18), blurRadius: 26, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "ROOM SAYA",
                  style: TextStyle(
                    color: _pink,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              _PillButton(label: "Tutup", outlined: true, onTap: _closeMyRoom),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Menunggu lawan...",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "${room.game.label} · ${room.stakeLabel} · Unit 07 · ${room.slotsFilled}/${room.slotsTotal} slot",
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Daftar Room",
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        Text(
          "${_openRooms.length} room aktif",
          style: const TextStyle(color: Colors.white38, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = [null, "eFootball", "FIFA", "Tanpa taruhan"];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = filters[i];
          final selected = _filterGame == filter;
          return _ToggleChip(
            label: filter ?? "Semua",
            selected: selected,
            onTap: () => setState(() => _filterGame = filter),
          );
        },
      ),
    );
  }

  Widget _buildHowToCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cara mainnya",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Buat room / gabung room lawan → kasir konfirmasi unit & durasi di tablet → skor akhir diinput kasir → point taruhan pemenang masuk otomatis.",
            style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(String pointText) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: const Color(0xff0D0B18),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Point kamu",
                  style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 11.5),
                ),
                Text(
                  "$pointText pt",
                  style: const TextStyle(color: _gold, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            _PillButton(
              label: _myRoom == null ? "Buat Room" : "Tutup Room",
              onTap: _myRoom == null ? _openCreateRoomSheet : _closeMyRoom,
              outlined: _myRoom != null,
            ),
          ],
        ),
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

// ---- Placeholder "fitur belum tersedia" (yang benar-benar tampil ke user) ----

class _RankComingSoonView extends StatelessWidget {
  const _RankComingSoonView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Cari Lawan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_purple, _pink],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _pink.withOpacity(.28),
                              blurRadius: 34,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_esports_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Fitur ini belum bisa digunakan\nuntuk sementara",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Mode Cari Lawan sedang kami siapkan. "
                        "Nantikan pembaruan berikutnya ya!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      _PillButton(
                        label: "Kembali",
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Buat Room bottom sheet ----

class _CreateRoomSheet extends StatefulWidget {
  final int availablePoint;

  const _CreateRoomSheet({required this.availablePoint});

  @override
  State<_CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<_CreateRoomSheet> {
  _Game _game = _Game.efootball;
  int? _presetStake = 0;
  final _customStakeController = TextEditingController();

  static const _presets = [0, 25, 50, 100];

  int? get _stake {
    final custom = _customStakeController.text.trim();
    if (custom.isNotEmpty) return int.tryParse(custom);
    return _presetStake;
  }

  bool get _isValid {
    final stake = _stake;
    return stake != null && stake >= 0 && stake <= widget.availablePoint;
  }

  @override
  void dispose() {
    _customStakeController.dispose();
    super.dispose();
  }

  void _selectPreset(int value) {
    setState(() {
      _presetStake = value;
      _customStakeController.clear();
    });
  }

  void _handleCreate() {
    final stake = _stake;
    if (stake == null || !_isValid) return;

    Navigator.pop(
      context,
      _Room(
        hostName: "Kamu",
        hostRank: "Room Kamu",
        game: _game,
        stake: stake,
        unit: "07",
        timeAgo: "Baru saja",
        avatarAsset: "assets/images/illustrations/img_mascot_avatar.png",
        slotsFilled: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stake = _stake;
    final overBudget = stake != null && stake > widget.availablePoint;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff231D3D), Color(0xff15121F)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Buat Room Baru",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Pilih game & tentukan point yang dipertaruhkan",
                  style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12.5),
                ),
                const SizedBox(height: 22),
                Text(
                  "Game",
                  style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ToggleChip(
                      label: _Game.efootball.label,
                      selected: _game == _Game.efootball,
                      onTap: () => setState(() => _game = _Game.efootball),
                    ),
                    const SizedBox(width: 10),
                    _ToggleChip(
                      label: _Game.fifa.label,
                      selected: _game == _Game.fifa,
                      onTap: () => setState(() => _game = _Game.fifa),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Taruhan Point",
                  style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in _presets)
                      _ToggleChip(
                        label: p == 0 ? "Tanpa taruhan" : "$p pt",
                        selected: _customStakeController.text.trim().isEmpty && _presetStake == p,
                        onTap: () => _selectPreset(p),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  "Atau masukkan jumlah lain",
                  style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customStakeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Contoh: 75",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(.3)),
                    suffixText: "pt",
                    suffixStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Point kamu: ${widget.availablePoint} pt",
                      style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 12),
                    ),
                    if (overBudget)
                      const Text(
                        "Melebihi point kamu",
                        style: TextStyle(color: Color(0xffFF5A71), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _PillButton(
                    label: "Buat Room",
                    expand: true,
                    onTap: _isValid ? _handleCreate : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Shared small widgets ----

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool outlined;
  final bool expand;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    this.onTap,
    this.outlined = false,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: outlined ? Border.all(color: enabled ? _pink : Colors.white24, width: 1.3) : null,
          gradient: outlined || !enabled
              ? null
              : const LinearGradient(colors: [_purple, _pink]),
          color: !outlined && !enabled ? Colors.white.withOpacity(.08) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: outlined ? (enabled ? _pink : Colors.white24) : (enabled ? Colors.white : Colors.white38),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: selected ? const LinearGradient(colors: [_purple, _pink]) : null,
          color: selected ? null : Colors.white.withOpacity(.04),
          border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final _Room room;
  final VoidCallback onGabung;

  const _RoomCard({required this.room, required this.onGabung});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .5,
                child: Image.asset(room.game.bgAsset, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xff0A0716).withOpacity(.55)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Image.asset(room.avatarAsset, width: 52, height: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              room.hostName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                room.hostRank,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${room.game.label} · Unit ${room.unit} · ${room.timeAgo}",
                          style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 11.5),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              room.stakeLabel,
                              style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${room.slotsFilled}/${room.slotsTotal} slot",
                              style: TextStyle(color: Colors.white.withOpacity(.4), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PillButton(label: "Gabung", onTap: onGabung),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
