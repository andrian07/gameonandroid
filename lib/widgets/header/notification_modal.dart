import 'package:flutter/material.dart';

import '../../models/notificationModel.dart';
import '../../pages/notification_page.dart';
import '../../services/notification_service.dart';

void showNotificationModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Notifikasi",
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.topCenter,
          child: _NotificationModalSheet(),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}

class _NotificationModalSheet extends StatefulWidget {
  const _NotificationModalSheet();

  @override
  State<_NotificationModalSheet> createState() => _NotificationModalSheetState();
}

class _NotificationModalSheetState extends State<_NotificationModalSheet> {
  final _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff231D3D), Color(0xff15121F)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(color: const Color(0xff9D4DFF).withOpacity(.25)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff7B2EFF).withOpacity(.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Notifikasi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.1)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: AnimatedBuilder(
                animation: _service,
                builder: (context, _) => _buildList(),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffD7B8FF),
                  side: BorderSide(
                    color: const Color(0xff9D4DFF).withOpacity(.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Lihat Semua Notifikasi",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_service.loading && _service.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_service.error != null && _service.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            _service.error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(.5),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final items = _service.items.take(5).toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            "Belum ada notifikasi",
            style: TextStyle(
              color: Colors.white.withOpacity(.5),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _NotificationPreviewTile(data: items[index]),
    );
  }
}

class _NotificationPreviewTile extends StatelessWidget {
  final NotificationModel data;

  const _NotificationPreviewTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showNotificationDetail(context, data),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.unread
            ? const Color(0xff2C2456)
            : Colors.white.withOpacity(.03),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: data.unread
                ? const Color(0xffA855F7)
                : Colors.white.withOpacity(.05),
            width: data.unread ? 3 : 1,
          ),
          top: BorderSide(color: Colors.white.withOpacity(data.unread ? .1 : .05)),
          right: BorderSide(color: Colors.white.withOpacity(data.unread ? .1 : .05)),
          bottom: BorderSide(color: Colors.white.withOpacity(data.unread ? .1 : .05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.color.withOpacity(data.unread ? .18 : .09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.unread ? data.color : data.color.withOpacity(.5),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: data.unread
                              ? Colors.white
                              : Colors.white.withOpacity(.6),
                          fontSize: 13,
                          fontWeight:
                              data.unread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (data.unread)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6, top: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xffA855F7),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  data.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(data.unread ? .55 : .38),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.timeLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(data.unread ? .38 : .28),
                    fontSize: 10.5,
                  ),
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
