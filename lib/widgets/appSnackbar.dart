import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Toast custom yang muncul dari ATAS layar (bukan SnackBar bawaan yang selalu
/// nempel di bawah). Dipakai untuk semua notifikasi sukses/error di app.
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Toast lama langsung dibuang supaya tidak menumpuk.
    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        isError: isError,
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

class _TopToast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onClosed;

  const _TopToast({
    required this.message,
    required this.isError,
    required this.onClosed,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoClose = Timer(const Duration(seconds: 3), _close);
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
    final color =
        widget.isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final icon = widget.isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(_anim),
            child: FadeTransition(
              opacity: _anim,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
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
