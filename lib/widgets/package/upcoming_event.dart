import 'package:flutter/material.dart';

import '../../models/roomCategoryModel.dart';
import '../../pages/booking_page.dart';

class UpcomingEventSection extends StatelessWidget {
  final List<RoomCategoryModel> categories;

  const UpcomingEventSection({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "PAKET FAVORIT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .3,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingPage()),
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
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xff5CE1E6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _RoomPackageCard(category: categories[index]),
          ),
        ),
      ],
    );
  }
}

class _RoomPackageCard extends StatelessWidget {
  final RoomCategoryModel category;

  const _RoomPackageCard({required this.category});

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
    final imageFile = category.image;
    final imagePath = (imageFile != null && imageFile.isNotEmpty)
        ? "assets/images/illustrations/$imageFile"
        : "assets/images/illustrations/img_room_regular.png";

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookingPage()),
        ),
        child: Container(
          width: 148,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(.08)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(imagePath, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xff0D0B1A).withOpacity(.9),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.durationLabel ?? "Per Jam",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (category.price != null)
                      Text(
                        _formatRupiah(category.price!),
                        style: const TextStyle(
                          color: Color(0xffF6B91A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
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
