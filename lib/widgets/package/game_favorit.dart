import 'package:flutter/material.dart';

import '../../pages/game_list_page.dart';

class _GameFavoritItem {
  final String name;
  final List<Color> gradient;
  final IconData icon;

  const _GameFavoritItem(this.name, this.gradient, this.icon);
}

/// Preview game populer di dashboard - daftar lengkap & filter kategori ada
/// di GameListPage. Belum ada cover art resmi tiap game, jadi dipakai kartu
/// ikon+gradient bergaya cover (konsisten dengan gaya GameListPage), bukan
/// foto box art berlisensi.
const _favorites = <_GameFavoritItem>[
  _GameFavoritItem(
    "Mobile Legends",
    [Color(0xff3B82F6), Color(0xff06B6D4)],
    Icons.shield_moon_rounded,
  ),
  _GameFavoritItem(
    "EA SPORTS FC 24",
    [Color(0xff0EA5E9), Color(0xff6366F1)],
    Icons.sports_soccer_rounded,
  ),
  _GameFavoritItem(
    "GTA V",
    [Color(0xff059669), Color(0xff115E59)],
    Icons.directions_car_rounded,
  ),
  _GameFavoritItem(
    "Tekken 8",
    [Color(0xffEF4444), Color(0xff7C3AED)],
    Icons.sports_mma_rounded,
  ),
  _GameFavoritItem(
    "Free Fire",
    [Color(0xffF97316), Color(0xffFACC15)],
    Icons.local_fire_department_rounded,
  ),
];

class GameFavoritSection extends StatelessWidget {
  const GameFavoritSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Game Favorit",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameListPage()),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Lihat Semua",
                      style: TextStyle(
                        color: Color(0xff5CE1E6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded,
                        color: Color(0xff5CE1E6), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _favorites.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _GameCoverCard(data: _favorites[i]),
          ),
        ),
      ],
    );
  }
}

class _GameCoverCard extends StatelessWidget {
  final _GameFavoritItem data;

  const _GameCoverCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GameListPage()),
        ),
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: data.gradient,
                  ),
                ),
              ),
              Center(
                child: Icon(data.icon, color: Colors.white.withOpacity(.92), size: 38),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xff0D0B1A).withOpacity(.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    data.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
