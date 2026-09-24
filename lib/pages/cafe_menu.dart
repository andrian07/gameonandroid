import 'package:flutter/material.dart';

import '../widgets/footer/custom_bottom_nav.dart';

// Halaman Cafe & Resto - HANYA menampilkan daftar menu (katalog). Pemesanan
// tidak dilakukan lewat app: user memesan langsung ke kasir / staff. Seluruh
// logika keranjang & pembayaran sudah dilepas dari halaman ini.

class _MenuItem {
  final String name;
  final int price;
  final String description;
  final IconData icon;
  final bool favorite;

  const _MenuItem({
    required this.name,
    required this.price,
    required this.description,
    required this.icon,
    this.favorite = false,
  });
}

class _MenuCategory {
  final String name;
  final IconData icon;
  final List<Color> gradient;
  final List<_MenuItem> items;

  const _MenuCategory({
    required this.name,
    required this.icon,
    required this.gradient,
    required this.items,
  });
}

const _categories = <_MenuCategory>[
  _MenuCategory(
    name: "Minuman",
    icon: Icons.local_cafe_rounded,
    gradient: [Color(0xff46A8FF), Color(0xff2F80ED)],
    items: [
      _MenuItem(
        name: "Es Teh Manis",
        price: 8000,
        description: "Teh melati diseduh segar, disajikan dingin",
        icon: Icons.emoji_food_beverage_rounded,
        favorite: true,
      ),
      _MenuItem(
        name: "Kopi Hitam",
        price: 10000,
        description: "Robusta lokal, pahit mantap penahan kantuk",
        icon: Icons.coffee_rounded,
      ),
      _MenuItem(
        name: "Cappuccino",
        price: 18000,
        description: "Espresso + steamed milk + foam lembut",
        icon: Icons.coffee_maker_rounded,
        favorite: true,
      ),
      _MenuItem(
        name: "Jus Alpukat",
        price: 15000,
        description: "Alpukat kental dengan drizzle cokelat",
        icon: Icons.local_drink_rounded,
      ),
      _MenuItem(
        name: "Air Mineral",
        price: 5000,
        description: "Botol 600ml",
        icon: Icons.water_drop_rounded,
      ),
    ],
  ),
  _MenuCategory(
    name: "Makanan",
    icon: Icons.restaurant_rounded,
    gradient: [Color(0xffFF8B56), Color(0xffF6631A)],
    items: [
      _MenuItem(
        name: "Nasi Goreng Spesial",
        price: 20000,
        description: "Nasi goreng + telur, ayam suwir, kerupuk",
        icon: Icons.rice_bowl_rounded,
        favorite: true,
      ),
      _MenuItem(
        name: "Mie Goreng",
        price: 18000,
        description: "Mie goreng bumbu rumahan, telur ceplok",
        icon: Icons.ramen_dining_rounded,
      ),
      _MenuItem(
        name: "Indomie Rebus",
        price: 12000,
        description: "Pakai telur, sawi, dan bawang goreng",
        icon: Icons.soup_kitchen_rounded,
      ),
      _MenuItem(
        name: "French Fries",
        price: 15000,
        description: "Kentang goreng renyah + saus sambal & mayo",
        icon: Icons.lunch_dining_rounded,
      ),
    ],
  ),
  _MenuCategory(
    name: "Snack",
    icon: Icons.fastfood_rounded,
    gradient: [Color(0xffB06CFF), Color(0xff7B2EFF)],
    items: [
      _MenuItem(
        name: "Chicken Wings",
        price: 20000,
        description: "6 pcs sayap ayam, saus honey atau spicy",
        icon: Icons.kebab_dining_rounded,
        favorite: true,
      ),
      _MenuItem(
        name: "Nachos Cheese",
        price: 17000,
        description: "Tortilla chips + lelehan keju + jalapeno",
        icon: Icons.tapas_rounded,
      ),
      _MenuItem(
        name: "Popcorn",
        price: 10000,
        description: "Caramel atau asin, porsi besar buat nobar",
        icon: Icons.local_movies_rounded,
      ),
    ],
  ),
];

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

class CafeMenuPage extends StatefulWidget {
  const CafeMenuPage({super.key});

  @override
  State<CafeMenuPage> createState() => _CafeMenuPageState();
}

class _CafeMenuPageState extends State<CafeMenuPage> {
  String _selectedCategory = "Semua";

  int get _totalItems =>
      _categories.fold(0, (sum, c) => sum + c.items.length);

  @override
  Widget build(BuildContext context) {
    final visibleCategories = _selectedCategory == "Semua"
        ? _categories
        : _categories.where((c) => c.name == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero(context)),
            SliverToBoxAdapter(child: _buildInfoNote()),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            for (final category in visibleCategories)
              SliverToBoxAdapter(child: _buildCategorySection(category)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff2A1B4D), Color(0xff17122B)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "$_totalItems menu",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xffFF8B56), Color(0xffFF4FD8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffFF4FD8).withValues(alpha: .35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_menu_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cafe & Resto",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Nikmati sambil main favoritmu",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xff46A8FF).withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xff46A8FF).withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xff8FD0FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Katalog menu. Untuk memesan, hubungi kasir atau staff kami "
              "langsung di outlet.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: .75),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = <(String, IconData)>[
      ("Semua", Icons.grid_view_rounded),
      for (final c in _categories) (c.name, c.icon),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (name, icon) = chips[index];
          final isActive = name == _selectedCategory;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xff7B2EFF), Color(0xffB06CFF)],
                      )
                    : null,
                color: isActive ? null : const Color(0xff171826),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: .08),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 15,
                      color: isActive ? Colors.white : Colors.white54),
                  const SizedBox(width: 7),
                  Text(
                    name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 13,
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

  Widget _buildCategorySection(_MenuCategory category) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(colors: category.gradient),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${category.items.length} item",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in category.items)
                    SizedBox(
                      width: cardWidth,
                      child: _MenuCard(item: item, gradient: category.gradient),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final List<Color> gradient;

  const _MenuCard({required this.item, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1B1836), Color(0xff131126)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: gradient),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.last.withValues(alpha: .3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              if (item.favorite)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xffF6B91A).withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: Color(0xffF6B91A), size: 12),
                      SizedBox(width: 3),
                      Text(
                        "Favorit",
                        style: TextStyle(
                          color: Color(0xffF6B91A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .45),
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xffF6B91A).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _formatRupiah(item.price),
              style: const TextStyle(
                color: Color(0xffF6B91A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}
