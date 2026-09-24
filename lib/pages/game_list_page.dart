import 'package:flutter/material.dart';

/// Daftar game yang tersedia untuk dimainkan di GameOn.
/// Data statis (belum ada endpoint) - gampang diganti ke API nanti.
class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameItem {
  final String name;
  final String category;
  final String platform; // "PS5" / "Mobile" / "PS5 & Mobile"
  final List<Color> gradient;
  final IconData icon;

  const _GameItem({
    required this.name,
    required this.category,
    required this.platform,
    required this.gradient,
    required this.icon,
  });
}

const _games = <_GameItem>[
  _GameItem(
    name: "eFootball 2024",
    category: "Sports",
    platform: "PS5 & Mobile",
    gradient: [Color(0xff2E7DFF), Color(0xff17C0C0)],
    icon: Icons.sports_soccer_rounded,
  ),
  _GameItem(
    name: "EA SPORTS FC 24",
    category: "Sports",
    platform: "PS5",
    gradient: [Color(0xff0EA5E9), Color(0xff6366F1)],
    icon: Icons.sports_soccer_rounded,
  ),
  _GameItem(
    name: "NBA 2K24",
    category: "Sports",
    platform: "PS5",
    gradient: [Color(0xffF97316), Color(0xffEF4444)],
    icon: Icons.sports_basketball_rounded,
  ),
  _GameItem(
    name: "Tekken 8",
    category: "Fighting",
    platform: "PS5",
    gradient: [Color(0xffEF4444), Color(0xff7C3AED)],
    icon: Icons.sports_mma_rounded,
  ),
  _GameItem(
    name: "Mortal Kombat 1",
    category: "Fighting",
    platform: "PS5",
    gradient: [Color(0xffB91C1C), Color(0xff1F2937)],
    icon: Icons.sports_mma_rounded,
  ),
  _GameItem(
    name: "Street Fighter 6",
    category: "Fighting",
    platform: "PS5",
    gradient: [Color(0xffF59E0B), Color(0xffDB2777)],
    icon: Icons.sports_kabaddi_rounded,
  ),
  _GameItem(
    name: "Gran Turismo 7",
    category: "Racing",
    platform: "PS5",
    gradient: [Color(0xff2563EB), Color(0xff9333EA)],
    icon: Icons.sports_motorsports_rounded,
  ),
  _GameItem(
    name: "Mobile Legends",
    category: "MOBA",
    platform: "Mobile",
    gradient: [Color(0xff3B82F6), Color(0xff06B6D4)],
    icon: Icons.shield_moon_rounded,
  ),
  _GameItem(
    name: "Free Fire",
    category: "Battle Royale",
    platform: "Mobile",
    gradient: [Color(0xffF97316), Color(0xffFACC15)],
    icon: Icons.local_fire_department_rounded,
  ),
  _GameItem(
    name: "Call of Duty",
    category: "FPS",
    platform: "PS5 & Mobile",
    gradient: [Color(0xff334155), Color(0xff0F172A)],
    icon: Icons.gps_fixed_rounded,
  ),
  _GameItem(
    name: "God of War Ragnarök",
    category: "Action",
    platform: "PS5",
    gradient: [Color(0xff1D4ED8), Color(0xffB91C1C)],
    icon: Icons.sports_esports_rounded,
  ),
  _GameItem(
    name: "Marvel's Spider-Man 2",
    category: "Action",
    platform: "PS5",
    gradient: [Color(0xffDC2626), Color(0xff1E3A8A)],
    icon: Icons.sports_esports_rounded,
  ),
  _GameItem(
    name: "GTA V",
    category: "Open World",
    platform: "PS5",
    gradient: [Color(0xff059669), Color(0xff115E59)],
    icon: Icons.directions_car_rounded,
  ),
  _GameItem(
    name: "Elden Ring",
    category: "RPG",
    platform: "PS5",
    gradient: [Color(0xffCA8A04), Color(0xff713F12)],
    icon: Icons.castle_rounded,
  ),
];

/// Jumlah game di daftar - dipakai widget lain (mis. StatsRow di dashboard).
int get gameListCount => _games.length;

class _GameListPageState extends State<GameListPage> {
  String _filter = "Semua";

  List<String> get _categories {
    final set = <String>{"Semua"};
    for (final g in _games) {
      set.add(g.category);
    }
    return set.toList();
  }

  List<_GameItem> get _filtered => _filter == "Semua"
      ? _games
      : _games.where((g) => g.category == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildFilters(),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .82,
                ),
                itemCount: _filtered.length,
                itemBuilder: (context, i) => _GameCard(data: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            "List Game",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            "${_games.length} game",
            style: TextStyle(
              color: Colors.white.withOpacity(.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final cats = _categories;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = cats[i];
          final active = c == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                      )
                    : null,
                color: active ? null : Colors.white.withOpacity(.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : Colors.white.withOpacity(.1),
                ),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white.withOpacity(.6),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _GameItem data;

  const _GameCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xff1F1B2E),
              content: Text(
                "${data.name} tersedia di GameOn. Pesan ruangan untuk mulai main!",
              ),
            ),
          );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff141527),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: data.gradient,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    data.icon,
                    color: Colors.white.withOpacity(.92),
                    size: 42,
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data.platform,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded,
                        color: Colors.white.withOpacity(.35), size: 10),
                    const SizedBox(width: 4),
                    Text(
                      data.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.5),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
