import 'package:flutter/material.dart';

import '../../models/userModel.dart';
import '../../services/notification_service.dart';
import 'notification_modal.dart';

class HomeHeader extends StatelessWidget {
  final UserModel? user;

  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName = user?.name.split(" ").first ?? "Player";
    final service = NotificationService.instance;
    service.ensureLoaded();

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            "assets/images/bgheader.png",
            fit: BoxFit.cover,
            alignment: Alignment.topRight,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xff090A17).withOpacity(.15),
                  const Color(0xff090A17),
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                "assets/images/icons/png/ic_avatar.png",
                width: 56,
                height: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $firstName!",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Game On! Member",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.6),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _HeaderIconButton(
                icon: Icons.search_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: service,
                builder: (context, _) => _HeaderIconButton(
                  icon: Icons.notifications_rounded,
                  badgeCount: service.unreadCount,
                  onTap: () => showNotificationModal(context),
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "PLAY",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                        height: 1,
                      ),
                    ),
                    const Text(
                      "MORE",
                      style: TextStyle(
                        color: Color(0xffE84DFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 23),
            if (badgeCount > 0)
              Positioned(
                top: 2,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xffFF4D4D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff090A17), width: 1.5),
                  ),
                  child: Text(
                    "$badgeCount",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
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
