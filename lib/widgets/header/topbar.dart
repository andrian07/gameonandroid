import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import 'notification_modal.dart';

/// Top identity bar: app logo + tagline on the left, notification bell
/// (with unread badge) on the right. Sits directly on the page background.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    service.ensureLoaded();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                  children: [
                    TextSpan(text: "GAME", style: TextStyle(color: Colors.white)),
                    TextSpan(
                      text: "ON",
                      style: TextStyle(color: Color(0xffA855F7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "LEVEL UP YOUR GAME",
                style: TextStyle(
                  color: Colors.white.withOpacity(.45),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: service,
          builder: (context, _) => _NotificationBell(
            unreadCount: service.unreadCount,
            onTap: () => showNotificationModal(context),
          ),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(.06),
          border: Border.all(color: Colors.white.withOpacity(.1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffFF3B3B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff090A17), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffFF3B3B).withOpacity(.55),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    unreadCount > 9 ? "9+" : "$unreadCount",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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
