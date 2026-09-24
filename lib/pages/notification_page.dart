import 'package:flutter/material.dart';

import '../models/notificationModel.dart';
import '../services/notification_service.dart';

/// Buka popup detail 1 notifikasi + tandai sudah dibaca. Dipakai halaman
/// Notifikasi maupun modal lonceng di header.
void showNotificationDetail(BuildContext context, NotificationModel data) {
  NotificationService.instance.markRead(id: data.id);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _NotificationDetailSheet(data: data),
  );
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.fetch();
  }

  void _openDetail(NotificationModel data) =>
      showNotificationDetail(context, data);

  Future<void> _deleteOne(NotificationModel n) async {
    try {
      await _service.delete(id: n.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notifikasi dihapus"),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xff1F1B2E),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghapus, coba lagi"),
            backgroundColor: Color(0xff1F1B2E),
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1F1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Hapus semua notifikasi?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          "Semua notifikasi akan dihapus permanen dan tidak bisa dikembalikan.",
          style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Hapus Semua",
              style: TextStyle(color: Color(0xffFF5A71), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Semua notifikasi dihapus"),
            backgroundColor: Color(0xff1F1B2E),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghapus, coba lagi"),
            backgroundColor: Color(0xff1F1B2E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _service.fetch,
                child: AnimatedBuilder(
                  animation: _service,
                  builder: (context, _) => _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_service.loading && _service.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_service.error != null && _service.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(.3), size: 40),
          const SizedBox(height: 12),
          Text(
            _service.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _service.fetch,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(.2)),
              ),
              child: const Text("Coba Lagi"),
            ),
          ),
        ],
      );
    }

    if (_service.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          Icon(Icons.notifications_off_rounded, color: Colors.white.withOpacity(.25), size: 40),
          const SizedBox(height: 12),
          Text(
            "Belum ada notifikasi",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _service.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final n = _service.items[index];
        return Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteOne(n),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: const Color(0xffFF3B3B).withOpacity(.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  "Hapus",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: _NotificationCard(
            data: n,
            onTap: () => _openDetail(n),
            onDelete: () => _deleteOne(n),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
          const Expanded(
            child: Text(
              "Notifikasi",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _service,
            builder: (context, _) {
              if (_service.items.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: const Color(0xff1F1B2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (v) {
                  if (v == 'read') _service.markRead();
                  if (v == 'clear') _clearAll();
                },
                itemBuilder: (context) => [
                  if (_service.unreadCount > 0)
                    const PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.done_all_rounded,
                              color: Color(0xffC44DFF), size: 18),
                          SizedBox(width: 10),
                          Text("Tandai semua dibaca",
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            color: Color(0xffFF5A71), size: 18),
                        SizedBox(width: 10),
                        Text("Hapus semua notifikasi",
                            style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
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

class _NotificationCard extends StatelessWidget {
  final NotificationModel data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.unread
                  ? [const Color(0xff2C2456), const Color(0xff211A40)]
                  : [const Color(0xff161422), const Color(0xff131120)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(
                color: data.unread
                    ? const Color(0xffA855F7)
                    : Colors.white.withOpacity(.05),
                width: data.unread ? 3.5 : 1,
              ),
              top: BorderSide(
                color: data.unread
                    ? const Color(0xff9D4DFF).withOpacity(.45)
                    : Colors.white.withOpacity(.05),
              ),
              right: BorderSide(
                color: data.unread
                    ? const Color(0xff9D4DFF).withOpacity(.45)
                    : Colors.white.withOpacity(.05),
              ),
              bottom: BorderSide(
                color: data.unread
                    ? const Color(0xff9D4DFF).withOpacity(.45)
                    : Colors.white.withOpacity(.05),
              ),
            ),
            boxShadow: data.unread
                ? [
                    BoxShadow(
                      color: const Color(0xff7B2EFF).withOpacity(.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(data.unread ? .18 : .09),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: data.unread
                      ? data.color
                      : data.color.withOpacity(.5),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.title,
                            style: TextStyle(
                              color: data.unread
                                  ? Colors.white
                                  : Colors.white.withOpacity(.6),
                              fontSize: 14,
                              fontWeight: data.unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (data.unread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xffA855F7).withOpacity(.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Baru",
                              style: TextStyle(
                                color: Color(0xffC9A6FF),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: onDelete,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.white.withOpacity(.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(data.unread ? .62 : .4),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          data.timeLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(data.unread ? .45 : .32),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Lihat detail",
                          style: TextStyle(
                            color: data.color.withOpacity(data.unread ? .9 : .5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: data.color.withOpacity(data.unread ? .9 : .5),
                            size: 14),
                      ],
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

/// Popup detail 1 notifikasi.
class _NotificationDetailSheet extends StatelessWidget {
  final NotificationModel data;

  const _NotificationDetailSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff211B3B), Color(0xff120F22)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(.16),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: data.color.withOpacity(.35)),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.timeLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.45),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data.message,
                style: TextStyle(
                  color: Colors.white.withOpacity(.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (data.detail.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detail",
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final e in data.detail.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.5),
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  e.value,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Tutup",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
