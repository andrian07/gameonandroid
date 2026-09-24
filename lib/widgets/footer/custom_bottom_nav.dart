import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../pages/profile_page.dart';
import '../../pages/rewards_page.dart';
import '../../pages/transaction_list.dart';
import 'qr_scan_modal.dart';

/// Single entry point for the bottom navigation bar. Every page that shows
/// a footer should use this widget instead of wiring [CustomBottomNav] by
/// hand, so the active-tab state and navigation between the sections
/// (Home, Tukar Point, QR, Riwayat, Akun) stay consistent.
class AppBottomNav extends StatefulWidget {
  final int initialIndex;

  const AppBottomNav({super.key, this.initialIndex = -1});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return CustomBottomNav(
      currentIndex: _currentIndex,
      onChanged: (index) {
        if (index == widget.initialIndex) return;

        if (index == 0 && Navigator.canPop(context)) {
          Navigator.popUntil(context, (route) => route.isFirst);
          return;
        }

        switch (index) {
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RewardsPage()),
            );
            return;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionListPage()),
            );
            return;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
            return;
        }

        setState(() => _currentIndex = index);
      },
    );
  }
}

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onChanged;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const _items = [
    (iconPath: "assets/images/icons/svg/ic_home.svg", title: "Home"),
    (iconPath: "assets/images/icons/svg/ic_gift.svg", title: "Tukar Point"),
    (iconPath: null, title: ""), // slot tengah, diisi tombol mascot terangkat
    (iconPath: "assets/images/icons/svg/ic_history.svg", title: "Riwayat"),
    (iconPath: "assets/images/icons/svg/ic_person.svg", title: "Akun"),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 86,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 74,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xff12131F),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xff6E3BFF).withOpacity(.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  if (item.iconPath == null) {
                    return const Expanded(child: SizedBox());
                  }
                  return Expanded(
                    child: _NavItem(
                      iconPath: item.iconPath!,
                      title: item.title,
                      active: currentIndex == index,
                      onTap: () => onChanged(index),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              bottom: 40,
              child: _CenterMascotButton(onTap: () => showQrScanModal(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xffB15CFF);
    const inactiveColor = Color(0xff8E8FA6);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                    )
                  : null,
            ),
            child: SvgPicture.asset(
              iconPath,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                active ? Colors.white : inactiveColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterMascotButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterMascotButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xff7B2EFF), Color(0xffE84DFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffE84DFF).withOpacity(.5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Container(
            color: const Color(0xff090A17),
            child: Image.asset(
              "assets/images/illustrations/img_mascot_nav.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
