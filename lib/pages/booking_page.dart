import 'package:flutter/material.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../widgets/appSnackbar.dart';

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------
const _kBg = Color(0xFF090A17);
const _kSurface = Color(0xFF15172A);
const _kSurfaceHi = Color(0xFF1C1F38);
const _kBorder = Color(0x14FFFFFF); // white 8%
const _kAccent = Color(0xFF7B2EFF);
const _kAccent2 = Color(0xFF9D4DFF);
const _kSuccess = Color(0xFF4ADE80);
const _kDanger = Color(0xFFFF6B6B);
const _kGradient = LinearGradient(colors: [_kAccent, _kAccent2]);

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------
class _BookingUnit {
  final int id;
  final int no;
  final String area; // "Smoking" | "NonSmoking"

  const _BookingUnit({required this.id, required this.no, required this.area});

  bool get isSmoking => area == "Smoking";
  String get areaLabel => isSmoking ? "Smoking" : "Non-smoking";
  String get label => "No.$no · $areaLabel";

  factory _BookingUnit.fromJson(Map<String, dynamic> j) => _BookingUnit(
        id: (j["booking_unit_id"] as num?)?.toInt() ?? 0,
        no: (j["unit_no"] as num?)?.toInt() ?? 0,
        area: j["area"]?.toString() ?? "NonSmoking",
      );
}

class _BookingRoom {
  final int bookingRoomId;
  final int categoryId;
  final String name;
  final int price1h;
  final int price2h;
  final String facilities;
  final String capacityLabel;
  final List<_BookingUnit> units;
  final IconData icon;
  final Color color;
  final bool isVip;

  const _BookingRoom({
    required this.bookingRoomId,
    required this.categoryId,
    required this.name,
    required this.price1h,
    required this.price2h,
    required this.facilities,
    required this.capacityLabel,
    required this.units,
    required this.icon,
    required this.color,
    required this.isVip,
  });

  /// Harga N jam - harus sama dengan Apimobile_model::price_for_duration di backend.
  int priceFor(int hours) {
    final h = hours < 1 ? 1 : hours;
    if (h == 1) return price1h;
    return price2h + (h - 2) * (price2h - price1h);
  }

  factory _BookingRoom.fromJson(Map<String, dynamic> j) {
    final name = j["name"]?.toString() ?? "";
    final upper = name.toUpperCase();
    final isVvip = upper.contains("VVIP");
    final isVip = isVvip || upper.contains("VIP");
    return _BookingRoom(
      bookingRoomId: (j["booking_room_id"] as num?)?.toInt() ?? 0,
      categoryId: (j["category_meja_id"] as num?)?.toInt() ?? 0,
      name: name,
      price1h: (j["price_1h"] as num?)?.toInt() ?? 0,
      price2h: (j["price_2h"] as num?)?.toInt() ?? 0,
      facilities: j["facilities"]?.toString() ?? "",
      capacityLabel: j["capacity_label"]?.toString() ?? "",
      units: (j["units"] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_BookingUnit.fromJson)
          .toList(),
      icon: isVip
          ? Icons.workspace_premium_rounded
          : Icons.sports_esports_rounded,
      color: isVvip
          ? const Color(0xFFFF6B4D)
          : isVip
          ? const Color(0xFFF6B91A)
          : const Color(0xFF46A8FF),
      isVip: isVip,
    );
  }
}

class _BookingBranch {
  final int id;
  final String name;
  final IconData icon;

  const _BookingBranch(this.id, this.name, this.icon);
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  static const _stepLabels = ["Cabang & Room", "Jadwal", "Konfirmasi"];

  static const _weekdays = [
    "Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min",
  ];

  static const _monthsShort = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des",
  ];

  static const _monthsFull = [
    "Januari", "Februari", "Maret", "April", "Mei", "Juni",
    "Juli", "Agustus", "September", "Oktober", "November", "Desember",
  ];

  static const _durations = [1, 2, 3, 4, 5];

  static const _timeSlots = [
    "10:00", "11:00", "12:00", "13:00", "14:00",
    "15:00", "16:00", "17:00", "18:00", "19:00",
    "20:00", "21:00", "22:00", "23:00", "00:00",
  ];

  // Cabang WAJIB dipilih dulu sebelum jadwal & jam bisa diatur.
  static const _branches = [
    _BookingBranch(1, "Danau Sentarum", Icons.storefront_rounded),
    _BookingBranch(2, "P.Aim", Icons.storefront_rounded),
  ];

  // Booking minimal sekian jam dari sekarang (harus sama dengan MIN_LEAD_HOURS di backend).
  static const _minLeadHours = 4;

  late final List<DateTime> _dateOptions = List.generate(
    7,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  int _step = 0;
  int? _branch;
  late DateTime _selectedDate = _dateOptions.first;
  int _durationHours = 2;
  String? _selectedTime;
  _BookingRoom? _selectedRoom;
  _BookingUnit? _selectedUnit;

  List<_BookingRoom> _rooms = [];
  bool _loadingRooms = false;
  bool _loadingSlots = false;
  bool _submitting = false;

  /// Jam ("HH:00") yang sudah dibooking orang lain di cabang + tanggal terpilih.
  Set<String> _bookedSlots = {};

  @override
  void initState() {
    super.initState();
    // Daftar room dimuat setelah cabang dipilih - katalognya beda per cabang
    // (mis. P.Aim tidak ada VVIP).
  }

  void _onBranchSelected(int id) {
    setState(() {
      _branch = id;
      _selectedRoom = null;
      _selectedUnit = null;
      _selectedTime = null;
      _bookedSlots = {};
      _rooms = [];
    });
    _loadRooms(id);
  }

  Future<void> _onRoomSelected(_BookingRoom room) async {
    setState(() {
      _selectedRoom = room;
      _selectedTime = null;
      _bookedSlots = {};
      // room dengan cuma 1 unit -> langsung pilih, user tinggal lanjut.
      _selectedUnit = room.units.length == 1 ? room.units.first : null;
    });
    if (_selectedUnit != null) {
      _loadBookedSlots();
    } else {
      await _openSeatPicker(room);
    }
  }

  void _onUnitSelected(_BookingUnit unit) {
    setState(() {
      _selectedUnit = unit;
      _selectedTime = null;
      _bookedSlots = {};
    });
    _loadBookedSlots();
  }

  Future<void> _openSeatPicker(_BookingRoom room) async {
    final picked = await showModalBottomSheet<_BookingUnit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeatPickerSheet(
        room: room,
        current: identical(_selectedRoom, room) ? _selectedUnit : null,
      ),
    );
    if (picked != null) _onUnitSelected(picked);
  }

  // --- derived -------------------------------------------------------------

  int get _estimatedPrice => _selectedRoom?.priceFor(_durationHours) ?? 0;

  _BookingBranch? get _branchObj {
    for (final b in _branches) {
      if (b.id == _branch) return b;
    }
    return null;
  }

  String get _endTimeLabel {
    if (_selectedTime == null) return "-";
    final endHour = (_slotHour(_selectedTime!) + _durationHours) % 24;
    return "${endHour.toString().padLeft(2, '0')}:00";
  }

  int _slotHour(String slot) => int.parse(slot.split(":")[0]);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Jam paling awal yang boleh dibooking (sekarang + lead time).
  DateTime get _earliestStart =>
      DateTime.now().add(const Duration(hours: _minLeadHours));

  /// Slot [slot] pada tanggal terpilih sudah lewat / terlalu mepet
  /// (kurang dari [_minLeadHours] jam dari sekarang).
  bool _isSlotTooSoon(String slot) {
    final dt = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _slotHour(slot));
    return dt.isBefore(_earliestStart);
  }

  /// Slot [index] termasuk dalam rentang sesi (start .. start+durasi).
  bool _isInSession(int index) {
    if (_selectedTime == null) return false;
    final start = _timeSlots.indexOf(_selectedTime!);
    return start != -1 && index > start && index < start + _durationHours;
  }

  /// Rentang [start, start+durasi) menabrak slot yang sudah dibooking.
  bool _rangeHitsBooked(String startSlot, int hours) {
    final start = _slotHour(startSlot);
    for (var i = 0; i < hours; i++) {
      final h = (start + i) % 24;
      if (_bookedSlots.contains("${h.toString().padLeft(2, '0')}:00")) {
        return true;
      }
    }
    return false;
  }

  String _apiDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  String _fullDate(DateTime d) =>
      "${_weekdays[d.weekday - 1]}, ${d.day} ${_monthsFull[d.month - 1]} ${d.year}";

  // --- data --------------------------------------------------------------

  Future<void> _loadRooms(int branch) async {
    setState(() => _loadingRooms = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) setState(() => _loadingRooms = false);
      return;
    }

    try {
      final response = await ApiService().postAuth(
        ApiUrl.bookingRooms,
        {"branch": branch},
        token,
      );
      if (!mounted) return;
      // abaikan respons kalau user sudah keburu ganti cabang lain
      if (branch != _branch) return;
      if (response["code"] == 200 && response["result"] is List) {
        final rooms = (response["result"] as List)
            .whereType<Map<String, dynamic>>()
            .map(_BookingRoom.fromJson)
            .toList();
        setState(() {
          _rooms = rooms;
          _loadingRooms = false;
        });
        return;
      }
    } catch (_) {
      // fall through - handled by empty state
    }
    if (mounted) setState(() => _loadingRooms = false);
  }

  Future<void> _loadBookedSlots() async {
    final branch = _branch;
    final unit = _selectedUnit;
    // Butuh cabang + kursi (unit) dulu - slot yang diblok dihitung per kursi.
    if (branch == null || unit == null) return;

    setState(() => _loadingSlots = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) setState(() => _loadingSlots = false);
      return;
    }

    try {
      final response = await ApiService().postAuth(
        ApiUrl.bookedSlots,
        {
          "branch": branch,
          "booking_unit_id": unit.id,
          "booking_date": _apiDate(_selectedDate),
        },
        token,
      );
      if (!mounted) return;
      if (response["code"] == 200 && response["result"] is List) {
        final slots =
            (response["result"] as List).map((e) => e.toString()).toSet();
        setState(() {
          _bookedSlots = slots;
          if (_selectedTime != null &&
              (_isSlotTooSoon(_selectedTime!) ||
                  _rangeHitsBooked(_selectedTime!, _durationHours))) {
            _selectedTime = null;
          }
        });
      }
    } catch (_) {
      // keep last known slots
    }
    if (mounted) setState(() => _loadingSlots = false);
  }

  // --- navigation ------------------------------------------------------

  void _goNext() {
    if (_step == 0 &&
        (_branch == null || _selectedRoom == null || _selectedUnit == null)) {
      return;
    }
    if (_step == 1) {
      if (_selectedTime == null) return;
      if (_isSlotTooSoon(_selectedTime!)) {
        setState(() => _selectedTime = null);
        AppSnackbar.show(
          context,
          "Jam itu sudah lewat. Booking minimal $_minLeadHours jam dari sekarang.",
          isError: true,
        );
        return;
      }
      if (_rangeHitsBooked(_selectedTime!, _durationHours)) {
        AppSnackbar.show(
          context,
          "Sebagian jam pada durasi ini sudah dibooking. Pilih jam atau durasi lain.",
          isError: true,
        );
        return;
      }
    }

    if (_step < 2) {
      setState(() => _step++);
    } else {
      _confirmBooking();
    }
  }

  void _goBack() {
    if (_step == 0) {
      Navigator.maybePop(context);
      return;
    }
    setState(() => _step--);
  }

  Future<void> _confirmBooking() async {
    if (_submitting) return;
    final room = _selectedRoom;
    final unit = _selectedUnit;
    if (_branch == null || room == null || unit == null || _selectedTime == null) {
      return;
    }

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        AppSnackbar.show(context, "Sesi habis, silakan login ulang.",
            isError: true);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final response = await ApiService().postAuth(
        ApiUrl.booking,
        {
          "branch": _branch,
          "booking_unit_id": unit.id,
          "booking_date": _apiDate(_selectedDate),
          "booking_time": _selectedTime,
          "duration_hours": _durationHours,
        },
        token,
      );
      if (!mounted) return;

      if (response["code"] == 200) {
        Navigator.pop(context);
        AppSnackbar.show(
          context,
          "Booking ${room.name} berhasil. Saldo terpotong ${_formatCurrency(_estimatedPrice)}.",
        );
        return;
      }
      AppSnackbar.show(
        context,
        response["result"]?.toString() ?? "Gagal menyimpan booking",
        isError: true,
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          "Server sedang gangguan, silakan coba lagi.",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // --- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildProgress(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, .03),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _buildStepBranchRoom(),
                    1 => _buildStepSchedule(),
                    _ => _buildStepConfirm(),
                  },
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 19),
          ),
          const Text(
            "Booking Room",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (_branchObj != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kAccent.withOpacity(.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_rounded,
                      color: Color(0xFFB06CFF), size: 13),
                  const SizedBox(width: 4),
                  Text(
                    _branchObj!.name,
                    style: const TextStyle(
                      color: Color(0xFFCBA6FF),
                      fontSize: 11,
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

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == _stepLabels.length - 1 ? 0 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: (done || active) ? _kGradient : null,
                      color: (done || active) ? null : Colors.white.withOpacity(.10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${i + 1}. ${_stepLabels[i]}",
                    style: TextStyle(
                      color: (done || active)
                          ? Colors.white
                          : Colors.white.withOpacity(.4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---- Step 1: cabang + room -------------------------------------------

  Widget _buildStepBranchRoom() {
    final gated = _branch == null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const _SectionHeader("Cabang", helper: "Pilih lokasi bermain kamu"),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final b in _branches) ...[
              Expanded(
                child: _BranchCard(
                  branch: b,
                  selected: _branch == b.id,
                  onTap: () => _onBranchSelected(b.id),
                ),
              ),
              if (b != _branches.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 22),

        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: gated ? .38 : 1,
          child: IgnorePointer(
            ignoring: gated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader("Pilih Room"),
                const SizedBox(height: 12),
                if (gated)
                  const SizedBox(height: 40)
                else if (_loadingRooms)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: CircularProgressIndicator(color: _kAccent)),
                  )
                else if (_rooms.isEmpty)
                  _hintBox("Kategori room tidak tersedia untuk cabang ini.")
                else
                  for (final room in _rooms) ...[
                    _RoomRow(
                      room: room,
                      selected: identical(_selectedRoom, room),
                      onTap: () => _onRoomSelected(room),
                    ),
                    const SizedBox(height: 10),
                  ],

                if (_selectedRoom != null &&
                    _selectedRoom!.units.length > 1) ...[
                  const SizedBox(height: 14),
                  _SeatSummaryCard(
                    unit: _selectedUnit,
                    onTap: () => _openSeatPicker(_selectedRoom!),
                  ),
                ],
              ],
            ),
          ),
        ),

        if (gated) ...[
          const SizedBox(height: 14),
          _hintBox("Pilih cabang dulu, lalu pilih room & kursi yang mau dibooking."),
        ],
      ],
    );
  }

  // ---- Step 2: schedule (tanggal / durasi / jam) ----------------------

  Widget _buildStepSchedule() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _hintBox(
          "Jam yang sudah dibooking untuk ${_selectedRoom?.name ?? 'room'} "
          "${_selectedUnit?.label ?? ''} di ${_branchObj?.name ?? 'cabang ini'} "
          "otomatis terkunci.",
        ),
        const SizedBox(height: 20),

        const _SectionHeader("Tanggal"),
        const SizedBox(height: 10),
        SizedBox(
          height: 74,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dateOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = _dateOptions[i];
                    return _DatePill(
                      top: i == 0 ? "Hari Ini" : _weekdays[d.weekday - 1],
                      day: "${d.day}",
                      month: _monthsShort[d.month - 1],
                      selected: _isSameDate(d, _selectedDate),
                      onTap: () {
                        setState(() => _selectedDate = d);
                        _loadBookedSlots();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _IconTile(
                icon: Icons.calendar_month_rounded,
                onTap: () => _pickCustomDate(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const _SectionHeader("Durasi bermain"),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final h in _durations) ...[
              Expanded(
                child: _PillButton(
                  label: "$h Jam",
                  selected: h == _durationHours,
                  onTap: () => setState(() {
                    _durationHours = h;
                    if (_selectedTime != null &&
                        _rangeHitsBooked(_selectedTime!, h)) {
                      _selectedTime = null;
                    }
                  }),
                ),
              ),
              if (h != _durations.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 22),

        Row(
          children: [
            const _SectionHeader("Jam mulai"),
            const Spacer(),
            if (_loadingSlots)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB06CFF),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _LegendDot(color: _kSurfaceHi, label: "Tersedia"),
            _LegendDot(color: _kAccent, label: "Dipilih"),
            _LegendDot(color: _kDanger, label: "Dibooking"),
            _LegendDot(color: Colors.white24, label: "Lewat"),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Booking minimal $_minLeadHours jam dari sekarang.",
          style: TextStyle(color: Colors.white.withOpacity(.4), fontSize: 10.5),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: [
            for (var i = 0; i < _timeSlots.length; i++)
              () {
                final booked = _bookedSlots.contains(_timeSlots[i]);
                final tooSoon = _isSlotTooSoon(_timeSlots[i]);
                return _TimeCell(
                  time: _timeSlots[i],
                  selected: _timeSlots[i] == _selectedTime,
                  inSession: _isInSession(i),
                  booked: booked,
                  tooSoon: tooSoon && !booked,
                  onTap: (booked || tooSoon)
                      ? null
                      : () => setState(() => _selectedTime = _timeSlots[i]),
                );
              }(),
          ],
        ),
        if (_selectedTime != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  color: Color(0xFFB06CFF), size: 15),
              const SizedBox(width: 6),
              Text(
                "Main $_selectedTime - $_endTimeLabel · $_durationHours jam",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---- Step 3: confirm ------------------------------------------------

  Widget _buildStepConfirm() {
    final room = _selectedRoom;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        const _SectionHeader("Ringkasan"),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _ReviewRow(Icons.place_rounded, "Cabang",
                  _branchObj?.name ?? "-"),
              _reviewDivider(),
              _ReviewRow(Icons.event_rounded, "Tanggal",
                  _fullDate(_selectedDate)),
              _reviewDivider(),
              _ReviewRow(Icons.schedule_rounded, "Jam",
                  "${_selectedTime ?? '-'} - $_endTimeLabel"),
              _reviewDivider(),
              _ReviewRow(Icons.timelapse_rounded, "Durasi",
                  "$_durationHours jam"),
              _reviewDivider(),
              _ReviewRow(Icons.meeting_room_rounded, "Room",
                  room?.name ?? "-"),
              _reviewDivider(),
              _ReviewRow(Icons.event_seat_rounded, "Kursi",
                  _selectedUnit?.label ?? "-"),
              if (room != null && room.capacityLabel.isNotEmpty) ...[
                _reviewDivider(),
                _ReviewRow(Icons.groups_rounded, "Kapasitas",
                    room.capacityLabel),
              ],
              if (room != null && room.facilities.isNotEmpty) ...[
                _reviewDivider(),
                _ReviewRow(Icons.chair_alt_rounded, "Fasilitas",
                    room.facilities),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionHeader("Rincian biaya"),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _priceLine(
                _durationHours <= 2
                    ? "Paket $_durationHours jam"
                    : "Paket 2 jam + ${_durationHours - 2} jam ekstra",
                _formatCurrency(_estimatedPrice),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: _kBorder),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Total",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  Text(
                    _formatCurrency(_estimatedPrice),
                    style: const TextStyle(
                      color: _kSuccess,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white38, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Saldo GameOn kamu akan langsung dipotong saat konfirmasi.",
                style: TextStyle(
                    color: Colors.white.withOpacity(.5), fontSize: 11.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Bottom bar --------------------------------------------------------

  Widget _buildBottomBar() {
    final canProceed = switch (_step) {
      0 => _branch != null && _selectedRoom != null && _selectedUnit != null,
      1 => _selectedTime != null,
      _ => !_submitting,
    };
    final showTotal = _step >= 1 && _selectedRoom != null;
    final cta = switch (_step) {
      0 => "Lanjut Atur Jadwal",
      1 => "Lanjut Konfirmasi",
      _ => _submitting ? "Memproses..." : "Konfirmasi & Bayar",
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (showTotal) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Total",
                      style: TextStyle(
                          color: Colors.white.withOpacity(.55), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(_estimatedPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
            ],
            if (_step > 0) ...[
              _IconTile(
                icon: Icons.arrow_back_rounded,
                onTap: _goBack,
                size: 50,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _PrimaryButton(
                label: cta,
                enabled: canProceed,
                loading: _submitting,
                onTap: _goNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- small builders -------------------------------------------------

  Widget _hintBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withOpacity(.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              color: Color(0xFFB06CFF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(height: 1, color: _kBorder),
      );

  Widget _priceLine(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _pickCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kAccent,
            surface: _kSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadBookedSlots();
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? helper;

  const _SectionHeader(this.title, {this.helper});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: TextStyle(
                color: Colors.white.withOpacity(.45), fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class _BranchCard extends StatelessWidget {
  final _BookingBranch branch;
  final bool selected;
  final VoidCallback onTap;

  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: selected ? _kGradient : null,
          color: selected ? null : _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : _kBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              branch.icon,
              color: selected ? Colors.white : const Color(0xFFB06CFF),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              branch.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String top;
  final String day;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  const _DatePill({
    required this.top,
    required this.day,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        decoration: BoxDecoration(
          gradient: selected ? _kGradient : null,
          color: selected ? null : _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.transparent : _kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              top,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              day,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              month,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _IconTile({required this.icon, required this.onTap, this.size = 74});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 50,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? _kGradient : null,
          color: selected ? null : _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.transparent : _kBorder),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color == _kSurfaceHi ? _kSurfaceHi : color.withOpacity(.9),
            borderRadius: BorderRadius.circular(3),
            border: color == _kSurfaceHi
                ? Border.all(color: Colors.white24)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.5), fontSize: 10.5)),
      ],
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String time;
  final bool selected;
  final bool inSession;
  final bool booked;
  final bool tooSoon;
  final VoidCallback? onTap;

  const _TimeCell({
    required this.time,
    required this.selected,
    required this.inSession,
    required this.booked,
    required this.onTap,
    this.tooSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    if (booked) {
      bg = _kDanger.withOpacity(.12);
      fg = const Color(0xFFFF9AA2);
      border = _kDanger.withOpacity(.35);
    } else if (tooSoon) {
      bg = Colors.white.withOpacity(.03);
      fg = Colors.white24;
      border = Colors.white.withOpacity(.05);
    } else if (selected) {
      bg = _kAccent;
      fg = Colors.white;
      border = Colors.transparent;
    } else if (inSession) {
      bg = _kAccent.withOpacity(.22);
      fg = Colors.white;
      border = _kAccent.withOpacity(.4);
    } else {
      bg = _kSurfaceHi;
      fg = Colors.white70;
      border = _kBorder;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (booked) ...[
              const Icon(Icons.lock_rounded,
                  size: 11, color: Color(0xFFFF9AA2)),
              const SizedBox(width: 4),
            ] else if (tooSoon) ...[
              const Icon(Icons.history_toggle_off_rounded,
                  size: 11, color: Colors.white24),
              const SizedBox(width: 4),
            ],
            Text(
              time,
              style: TextStyle(
                color: fg,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                decoration: booked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu di step 1 yang menampilkan kursi terpilih / mengajak buka modal.
class _SeatSummaryCard extends StatelessWidget {
  final _BookingUnit? unit;
  final VoidCallback onTap;

  const _SeatSummaryCard({required this.unit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final has = unit != null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: has ? _kAccent.withOpacity(.10) : _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: has ? _kAccent : _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: has ? _kGradient : null,
                color: has ? null : _kSurfaceHi,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event_seat_rounded,
                color: has ? Colors.white : Colors.white38,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    has ? "Kursi No.${unit!.no}" : "Pilih Kursi",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    has
                        ? "${unit!.areaLabel} area · ketuk untuk ganti"
                        : "Ketuk untuk memilih nomor kursi",
                    style: TextStyle(
                        color: Colors.white.withOpacity(.5), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              has ? Icons.edit_rounded : Icons.chevron_right_rounded,
              color: has ? const Color(0xFFB06CFF) : Colors.white38,
              size: has ? 16 : 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet pemilih kursi - layout ala denah tempat duduk.
class _SeatPickerSheet extends StatefulWidget {
  final _BookingRoom room;
  final _BookingUnit? current;

  const _SeatPickerSheet({required this.room, required this.current});

  @override
  State<_SeatPickerSheet> createState() => _SeatPickerSheetState();
}

class _SeatPickerSheetState extends State<_SeatPickerSheet> {
  _BookingUnit? _sel;

  @override
  void initState() {
    super.initState();
    _sel = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final smoking = room.units.where((u) => u.isSmoking).toList();
    final nonSmoking = room.units.where((u) => !u.isSmoking).toList();

    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 6),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        room.color.withOpacity(.4),
                        room.color.withOpacity(.14),
                      ]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(room.icon, color: room.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Pilih Kursi",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "${room.name} · ${room.units.length} kursi",
                          style: TextStyle(
                              color: Colors.white.withOpacity(.5),
                              fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    if (smoking.isNotEmpty)
                      _group("Smoking Area", smoking),
                    if (nonSmoking.isNotEmpty)
                      _group("Non-smoking Area", nonSmoking),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: _PrimaryButton(
                label: _sel == null
                    ? "Pilih nomor kursi dulu"
                    : "Pilih Kursi No.${_sel!.no}",
                enabled: _sel != null,
                loading: false,
                onTap: () => Navigator.pop(context, _sel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<_BookingUnit> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kSurfaceHi,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(.6),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final u in list)
              _SeatTile(
                no: u.no,
                selected: _sel?.id == u.id,
                onTap: () => setState(() => _sel = u),
              ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _SeatTile extends StatelessWidget {
  final int no;
  final bool selected;
  final VoidCallback onTap;

  const _SeatTile({
    required this.no,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 62,
        height: 64,
        decoration: BoxDecoration(
          gradient: selected ? _kGradient : null,
          color: selected ? null : _kSurfaceHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : _kBorder,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kAccent.withOpacity(.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_rounded,
              size: 20,
              color: selected ? Colors.white : Colors.white38,
            ),
            const SizedBox(height: 2),
            Text(
              "$no",
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  final _BookingRoom room;
  final bool selected;
  final VoidCallback onTap;

  const _RoomRow({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(.10) : _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _kAccent : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    room.color.withOpacity(.35),
                    room.color.withOpacity(.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(room.icon, color: room.color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (room.isVip) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6B91A).withOpacity(.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "VIP",
                            style: TextStyle(
                              color: Color(0xFFF6B91A),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.facilities.isEmpty
                        ? "${room.units.length} unit tersedia"
                        : room.facilities,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.55),
                        fontSize: 11,
                        height: 1.3),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        "${_formatCurrency(room.price1h)}/jam",
                        style: const TextStyle(
                          color: _kSuccess,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "  ·  2 jam ${_formatCurrency(room.price2h)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (room.capacityLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "Kapasitas ${room.capacityLabel} · ${room.units.length} unit",
                      style: TextStyle(
                          color: Colors.white.withOpacity(.4), fontSize: 10),
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      "${room.units.length} unit",
                      style: TextStyle(
                          color: Colors.white.withOpacity(.4), fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? _kAccent : Colors.white24,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReviewRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB06CFF), size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 12.5)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled && !loading ? onTap : null,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _kGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: _kAccent.withOpacity(.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
        ),
      ),
    );
  }
}

String _formatCurrency(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final posFromRight = digits.length - i;
    buffer.write(digits[i]);
    if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(".");
  }
  return "Rp$buffer";
}
