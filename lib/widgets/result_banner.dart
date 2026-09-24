import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Banner hasil aksi (mis. Top Up berhasil / gagal) yang meluncur dari ATAS
/// layar. Lebih menonjol dari AppSnackbar: ada judul, pesan, ikon besar, dan
/// pill status. Auto-hilang ~4 detik, atau ketuk untuk menutup.
class ResultBanner {
  ResultBanner._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    required bool success,
    required String title,
    required String message,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerBody(
        success: success,
        title: title,
        message: message,
        onClosed: () {
          if (_entry == entry) {
            entry.remove();
            _entry = null;
          }
        },
      ),
    );

    _entry = entry;
    overlay.insert(entry);
  }
}

class _BannerBody extends StatefulWidget {
  final bool success;
  final String title;
  final String message;
  final VoidCallback onClosed;

  const _BannerBody({
    required this.success,
    required this.title,
    required this.message,
    required this.onClosed,
  });

  @override
  State<_BannerBody> createState() => _BannerBodyState();
}

class _BannerBodyState extends State<_BannerBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoClose = Timer(const Duration(milliseconds: 4200), _close);
  }

  Future<void> _close() async {
    _autoClose?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onClosed();
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = widget.success;
    final accent = ok ? const Color(0xff2ED573) : const Color(0xffFF4D5E);
    final icon =
        ok ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1.2),
              end: Offset.zero,
            ).animate(_anim),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, .6),
              ),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xff231D3D), Color(0xff17131F)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent.withOpacity(.45)),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(.28),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(.16),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withOpacity(.5)),
                          ),
                          child: Icon(icon, color: accent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      ok ? "Berhasil" : "Gagal",
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                        letterSpacing: .3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.message,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Colors.white.withOpacity(.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _close,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
