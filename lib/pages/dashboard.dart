import 'package:flutter/material.dart';
import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/navigation/appRouteObserver.dart';
import '../core/storage/sessionManager.dart';
import '../models/roomCategoryModel.dart';
import '../models/userModel.dart';
import '../services/member_approval_service.dart';
import '../services/push_service.dart';
import '../widgets/package/upcoming_event.dart';
import '../widgets/package/game_favorit.dart';
import '../widgets/package/promo_event.dart';
import '../widgets/banner/promobanner.dart';
import '../widgets/header/header.dart';
import '../widgets/header/pin_setup_modal.dart';
import '../widgets/header/quickmenu.dart';
import '../widgets/footer/custom_bottom_nav.dart';
import '../widgets/package/wallet_card.dart';
import '../widgets/package/stats_row.dart';
import 'login.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  UserModel? _user;
  bool _loading = true;
  List<RoomCategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadSessionUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Kembali ke dashboard dari halaman lain (mis. selesai booking) - segarkan
  /// saldo/point supaya angka di kartu stats langsung ikut ter-update.
  @override
  void didPopNext() {
    _refreshCustomerDetail();
  }

  Future<void> _loadSessionUser() async {
    final cachedUser = await SessionManager.getUser();

    if (mounted) {
      setState(() {
        _user = cachedUser;
        _loading = false;
      });
    }

    await _refreshCustomerDetail();
    await _loadRoomCategories();
    await _checkPin();

    // Mulai pantau permintaan konfirmasi pembayaran dari kasir (Potong Saldo).
    if (await SessionManager.getToken() != null) {
      MemberApprovalService.instance.start();
      // Jaring pengaman: pastikan FCM token perangkat terdaftar untuk akun ini.
      PushService.instance.registerAfterLogin();
    }
  }

  Future<void> _loadRoomCategories() async {
    try {
      final response = await ApiService().post(ApiUrl.roomCategories, {});
      if (response["code"] == 200 && response["result"] is List) {
        final categories = (response["result"] as List)
            .whereType<Map<String, dynamic>>()
            .map(RoomCategoryModel.fromJson)
            .toList();

        if (!mounted) return;
        setState(() => _categories = categories);
      }
    } catch (_) {
      // Biarkan daftar kategori tetap kosong jika gagal - section akan disembunyikan.
    }
  }

  Future<void> _checkPin() async {
    if (!mounted || _user?.hasPin == true) return;

    final saved = await showPinSetupModal(context);
    if (saved && mounted) {
      setState(() => _user = _user?.copyWith(hasPin: true));
    }
  }

  Future<void> _refreshCustomerDetail() async {
    final token = await SessionManager.getToken();
    if (token == null) return;

    try {
      final response = await ApiService().postAuth(
        ApiUrl.customerDetail,
        {},
        token,
      );

      if (response["code"] == 200) {
        final user = UserModel.fromJson(response["result"]);
        await SessionManager.saveUser(user);

        if (!mounted) return;
        setState(() => _user = user);
      } else if (response["code"] == 401) {
        MemberApprovalService.instance.stop();
        await SessionManager.logout();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (_) {
      // Biarkan data cache lama tetap tampil jika request gagal (mis. offline).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSessionUser,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: HomeHeader(user: _user)),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    SliverToBoxAdapter(child: WalletCard(user: _user)),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    SliverToBoxAdapter(child: StatsRow(user: _user)),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),

                    const SliverToBoxAdapter(child: QuickMenu()),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),

                    const SliverToBoxAdapter(child: PromoBanner()),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),

                    const SliverToBoxAdapter(child: GameFavoritSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),

                    const SliverToBoxAdapter(child: PromoEventSection()),
                    const SliverToBoxAdapter(child: SizedBox(height: 26)),

                    SliverToBoxAdapter(
                      child: UpcomingEventSection(categories: _categories),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const AppBottomNav(initialIndex: 0),
    );
  }
}
