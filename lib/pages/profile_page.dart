import 'package:flutter/material.dart';

import '../core/api/apiService.dart';
import '../core/api/apiUrl.dart';
import '../core/storage/sessionManager.dart';
import '../models/userModel.dart';
import '../services/member_approval_service.dart';
import '../widgets/appSnackbar.dart';
import '../widgets/footer/custom_bottom_nav.dart';
import '../widgets/header/pin_setup_modal.dart';
import 'info_page.dart';
import 'login.dart';

const _avatarGradients = [
  [Color(0xff7B2EFF), Color(0xff9D4DFF)],
  [Color(0xff46A8FF), Color(0xff2F80ED)],
  [Color(0xffFF6B4D), Color(0xffFF8B56)],
  [Color(0xff2ED573), Color(0xff17A85A)],
  [Color(0xffFF5A71), Color(0xffE0355A)],
  [Color(0xffF6B91A), Color(0xffE0951A)],
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Diisi dari database (SessionManager cache -> /apimobile/customer_detail).
  String _name = "";
  String _phone = "";
  String _email = "";
  String _address = "";
  bool _verified = false;
  int _avatarIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Tampilkan dulu data cache biar instan, lalu segarkan dari server.
  Future<void> _loadProfile() async {
    final cached = await SessionManager.getUser();
    if (cached != null && mounted) {
      setState(() {
        _applyUser(cached);
        _loading = false;
      });
    }

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

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
        setState(() {
          _applyUser(user);
          _loading = false;
        });
      } else if (response["code"] == 401) {
        MemberApprovalService.instance.stop();
        await SessionManager.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      // Biarkan data cache/lama tetap tampil kalau request gagal (mis. offline).
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyUser(UserModel user) {
    _name = user.name;
    _phone = user.phone;
    _email = user.email;
    _address = user.address;
    _verified = user.verification == "Y";
  }

  /// Simpan 1 field profil ke server (/apimobile/update_profile).
  /// [field] = name | phone | email | address. Return true kalau sukses.
  Future<bool> _submitProfileField(String field, String value) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) AppSnackbar.show(context, "Sesi berakhir, silakan login ulang.", isError: true);
      return false;
    }

    try {
      final response = await ApiService().postAuth(
        ApiUrl.updateProfile,
        {field: value},
        token,
      );

      if (response["code"] == 200) {
        final user = UserModel.fromJson(response["result"]);
        await SessionManager.saveUser(user);
        if (!mounted) return true;
        setState(() => _applyUser(user));
        AppSnackbar.show(context, "Profil berhasil diperbarui");
        return true;
      }

      if (!mounted) return false;
      AppSnackbar.show(
        context,
        response["result"]?.toString() ?? "Gagal menyimpan perubahan",
        isError: true,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      AppSnackbar.show(context, "Server sedang gangguan, coba lagi.", isError: true);
      return false;
    }
  }

  /// Kirim ubah password ke server (/apimobile/update_password).
  Future<bool> _submitPassword(String current, String newPass) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) AppSnackbar.show(context, "Sesi berakhir, silakan login ulang.", isError: true);
      return false;
    }

    try {
      final response = await ApiService().postAuth(
        ApiUrl.updatePassword,
        {"current_password": current, "new_password": newPass},
        token,
      );

      if (response["code"] == 200) {
        if (!mounted) return true;
        AppSnackbar.show(context, "Password berhasil diubah");
        return true;
      }

      if (!mounted) return false;
      AppSnackbar.show(
        context,
        response["result"]?.toString() ?? "Gagal mengubah password",
        isError: true,
      );
      return false;
    } catch (_) {
      if (!mounted) return false;
      AppSnackbar.show(context, "Server sedang gangguan, coba lagi.", isError: true);
      return false;
    }
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r"\s+"));
    final first = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : "";
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : "";
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff090A17),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            if (_loading)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: Color(0xff9D4DFF),
                ),
              ),
            SliverToBoxAdapter(child: _buildAvatarSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildFieldsCard()),
            ),
            SliverToBoxAdapter(child: _buildSectionDivider()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: _buildHelpCard()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(initialIndex: 4),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
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
          const Text(
            "Profil Saya",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    final gradient = _avatarGradients[_avatarIndex];

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(.45),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: GestureDetector(
                    onTap: _showAvatarModal,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xff1F1B2E),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff090A17),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _email,
            style: TextStyle(color: Colors.white.withOpacity(.5), fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1B1836), Color(0xff141227)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        children: [
          _ProfileFieldRow(
            icon: Icons.person_outline_rounded,
            color: const Color(0xffA855F7),
            label: "Nama",
            value: _name,
            onTap: () => _showEditModal(
              title: "Nama",
              icon: Icons.person_outline_rounded,
              color: const Color(0xffA855F7),
              label: "Nama Lengkap",
              initialValue: _name,
              onSaved: (v) => _submitProfileField("name", v),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.phone_outlined,
            color: const Color(0xff46A8FF),
            label: "No Telpon",
            value: _phone,
            onTap: () => _showEditModal(
              title: "No Telpon",
              icon: Icons.phone_outlined,
              color: const Color(0xff46A8FF),
              label: "Nomor Telpon",
              initialValue: _phone,
              keyboardType: TextInputType.phone,
              onSaved: (v) => _submitProfileField("phone", v),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.email_outlined,
            color: const Color(0xffFF8B56),
            label: "Email",
            value: _email,
            onTap: () => _showEditModal(
              title: "Email",
              icon: Icons.email_outlined,
              color: const Color(0xffFF8B56),
              label: "Alamat Email",
              initialValue: _email,
              keyboardType: TextInputType.emailAddress,
              onSaved: (v) => _submitProfileField("email", v),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.location_on_outlined,
            color: const Color(0xff2ED573),
            label: "Alamat",
            value: _address,
            onTap: () => _showEditModal(
              title: "Alamat",
              icon: Icons.location_on_outlined,
              color: const Color(0xff2ED573),
              label: "Alamat Lengkap",
              initialValue: _address,
              maxLines: 3,
              onSaved: (v) => _submitProfileField("address", v),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.verified_outlined,
            color: const Color(0xffF6B91A),
            label: "Status Verifikasi",
            value: _verified ? "Terverifikasi" : "Belum Terverifikasi",
            onTap: _showVerifiedModal,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (_verified
                            ? const Color(0xff2ED573)
                            : const Color(0xffFF5A71))
                        .withOpacity(.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _verified ? "Aktif" : "Pending",
                    style: TextStyle(
                      color: _verified
                          ? const Color(0xff2ED573)
                          : const Color(0xffFF5A71),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white30,
                  size: 20,
                ),
              ],
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.pin_outlined,
            color: const Color(0xffFF5A71),
            label: "PIN",
            value: "••••••",
            onTap: () => showUpdatePinModal(context),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.lock_outline_rounded,
            color: const Color(0xff9D4DFF),
            label: "Password",
            value: "••••••••",
            onTap: _showPasswordModal,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 1,
    color: Colors.white.withOpacity(.06),
  );

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      height: 1,
      color: Colors.white.withOpacity(.1),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff1B1836), Color(0xff141227)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        children: [
          _ProfileFieldRow(
            icon: Icons.help_outline_rounded,
            color: const Color(0xff46A8FF),
            label: "Bantuan",
            value: "FAQ",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _FaqPage()),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.description_outlined,
            color: const Color(0xffA855F7),
            label: "Kebijakan",
            value: "Syarat & Ketentuan",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _TermsPage()),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.support_agent_rounded,
            color: const Color(0xff2ED573),
            label: "Dukungan",
            value: "Hubungi Kami",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _ContactUsPage()),
            ),
          ),
          _divider(),
          _ProfileFieldRow(
            icon: Icons.power_settings_new_rounded,
            color: const Color(0xffFF5A71),
            label: "Akun",
            value: "Keluar",
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xff1F1B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Keluar Akun",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Apakah kamu yakin ingin keluar dari akun ini?",
            style: TextStyle(color: Colors.white.withOpacity(.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                "Batal",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                "Keluar",
                style: TextStyle(
                  color: Color(0xffFF5A71),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    MemberApprovalService.instance.stop();
    await SessionManager.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showAvatarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff231D3D), Color(0xff15121F)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: const Color(0xff9D4DFF).withOpacity(.25),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalHandle(context),
                  const SizedBox(height: 14),
                  const Text(
                    "Ubah Foto Profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Pilih warna avatar kamu",
                    style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: List.generate(_avatarGradients.length, (index) {
                      final gradient = _avatarGradients[index];
                      final selected = index == _avatarIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _avatarIndex = index);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Foto profil berhasil diperbarui"),
                              backgroundColor: Color(0xff1F1B2E),
                            ),
                          );
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient,
                            ),
                            border: selected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVerifiedModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool sending = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff231D3D), Color(0xff15121F)],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                      color: const Color(0xffF6B91A).withOpacity(.25)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalHandle(context),
                    const SizedBox(height: 18),
                    Icon(
                      _verified
                          ? Icons.verified_rounded
                          : Icons.mark_email_unread_outlined,
                      color: _verified
                          ? const Color(0xff2ED573)
                          : const Color(0xffF6B91A),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _verified
                          ? "Akun Sudah Terverifikasi"
                          : "Akun Belum Terverifikasi",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _verified
                          ? "Data diri kamu sudah diverifikasi. Kamu bisa menikmati semua fitur GameOn tanpa batasan."
                          : "Kami akan mengirim link verifikasi ke email kamu"
                              "${_email.isEmpty ? "" : " ($_email)"}. "
                              "Buka email lalu klik link tersebut untuk mengaktifkan akun.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.6),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    if (!_verified) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xff7B2EFF), Color(0xff9D4DFF)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: sending
                                ? null
                                : () async {
                                    setModalState(() => sending = true);
                                    final ok = await _requestVerification();
                                    if (!ctx.mounted) return;
                                    if (ok) {
                                      Navigator.pop(ctx);
                                    } else {
                                      setModalState(() => sending = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Kirim Link Verifikasi ke Email",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Minta server mengirim email berisi link verifikasi ke email customer.
  Future<bool> _requestVerification() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        AppSnackbar.show(context, "Sesi berakhir, silakan login ulang.",
            isError: true);
      }
      return false;
    }

    try {
      final response = await ApiService().postAuth(
        ApiUrl.requestVerification,
        {},
        token,
      );

      if (!mounted) return response["code"] == 200;

      if (response["code"] == 200) {
        AppSnackbar.show(
          context,
          "Link verifikasi sudah dikirim ke email kamu. Cek inbox / folder spam.",
        );
        return true;
      }

      AppSnackbar.show(
        context,
        response["result"]?.toString() ?? "Gagal mengirim email verifikasi",
        isError: true,
      );
      return false;
    } on NetworkException catch (e) {
      if (!mounted) return false;
      AppSnackbar.show(context, e.message, isError: true);
      return false;
    } catch (e) {
      // Endpoint ini terkonfirmasi jalan (401 JSON valid untuk token salah),
      // jadi exception di sini kemungkinan besar respons non-JSON (mis. 500
      // dari server saat proses kirim email gagal) - dicatat supaya kelihatan
      // di console saat debug, bukan cuma pesan generik ke user.
      debugPrint("request_verification error: $e");
      if (!mounted) return false;
      AppSnackbar.show(context, "Server sedang gangguan, coba lagi.",
          isError: true);
      return false;
    }
  }

  // Modal khusus ubah password: butuh password lama + baru sekaligus.
  void _showPasswordModal() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    const color = Color(0xff9D4DFF);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool saving = false;

        InputDecoration deco(String hint, bool obscure, VoidCallback toggle) {
          OutlineInputBorder b(Color c) => OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c),
              );
          return InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(.35)),
            filled: true,
            fillColor: Colors.white.withOpacity(.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: b(Colors.white.withOpacity(.1)),
            enabledBorder: b(Colors.white.withOpacity(.1)),
            focusedBorder: b(color),
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 19,
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xff231D3D), Color(0xff15121F)],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(color: color.withOpacity(.25)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modalHandle(ctx),
                      const SizedBox(height: 14),
                      const Text(
                        "Ubah Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "PASSWORD LAMA",
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: currentCtrl,
                        obscureText: obscureCurrent,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: deco(
                          "Password sekarang",
                          obscureCurrent,
                          () => setModalState(
                              () => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "PASSWORD BARU",
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: newCtrl,
                        obscureText: obscureNew,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: deco(
                          "Minimal 6 karakter",
                          obscureNew,
                          () => setModalState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(.75)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final cur = currentCtrl.text.trim();
                                    final np = newCtrl.text.trim();
                                    if (cur.isEmpty || np.isEmpty) {
                                      AppSnackbar.show(
                                        context,
                                        "Password lama dan baru wajib diisi.",
                                        isError: true,
                                      );
                                      return;
                                    }
                                    if (np.length < 6) {
                                      AppSnackbar.show(
                                        context,
                                        "Password baru minimal 6 karakter.",
                                        isError: true,
                                      );
                                      return;
                                    }
                                    setModalState(() => saving = true);
                                    final ok = await _submitPassword(cur, np);
                                    if (!ctx.mounted) return;
                                    if (ok) {
                                      Navigator.pop(ctx);
                                    } else {
                                      setModalState(() => saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Simpan Password",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: .3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditModal({
    required String title,
    required IconData icon,
    required Color color,
    required String label,
    required String initialValue,
    // Kembalikan true kalau simpan ke server berhasil (modal ditutup).
    // Kembalikan false kalau gagal (modal tetap terbuka, error sudah ditampilkan).
    required Future<bool> Function(String) onSaved,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    final controller = TextEditingController(text: initialValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool obscure = obscureText;
        bool saving = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xff231D3D), Color(0xff15121F)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(color: color.withOpacity(.25)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _modalHandle(ctx),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withOpacity(.7)],
                              ),
                            ),
                            child: Icon(icon, color: Colors.white, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Edit $title",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.06),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(.1),
                                ),
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
                      const SizedBox(height: 18),
                      Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        obscureText: obscureText ? obscure : false,
                        keyboardType: keyboardType,
                        maxLines: obscureText ? 1 : maxLines,
                        maxLength: maxLength,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(.04),
                          counterStyle: TextStyle(
                            color: Colors.white.withOpacity(.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(.1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.white.withOpacity(.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: color),
                          ),
                          suffixIcon: obscureText
                              ? IconButton(
                                  onPressed: () => setModalState(
                                    () => obscure = !obscure,
                                  ),
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white38,
                                    size: 19,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(.75)],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final value = controller.text.trim();
                                    if (value.isEmpty) return;
                                    setModalState(() => saving = true);
                                    final ok = await onSaved(value);
                                    if (!ctx.mounted) return;
                                    if (ok) {
                                      Navigator.pop(ctx);
                                    } else {
                                      setModalState(() => saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Simpan Perubahan",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: .3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modalHandle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Center(
      child: Container(
        width: (screenWidth * 0.12).clamp(44.0, 64.0),
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.2),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileFieldRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white30,
                        size: 20,
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _FaqPage extends StatelessWidget {
  const _FaqPage();

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: "FAQ",
      child: Column(
        children: const [
          InfoSectionCard(
            icon: Icons.account_balance_wallet_rounded,
            color: Color(0xff46A8FF),
            title: "Bagaimana cara top up saldo?",
            description:
                "Buka menu Top Up di halaman utama, pilih metode pembayaran dan nominal, lalu ikuti instruksi pembayaran hingga selesai.",
          ),
          InfoSectionCard(
            icon: Icons.event_available_rounded,
            color: Color(0xff2ED573),
            title: "Bagaimana cara booking unit PS?",
            description:
                "Masuk ke menu Booking, pilih unit dan jadwal yang tersedia, lalu konfirmasi pembayaran menggunakan saldo atau cash di kasir.",
          ),
          InfoSectionCard(
            icon: Icons.card_giftcard_rounded,
            color: Color(0xffFF8B56),
            title: "Bagaimana cara menukar poin?",
            description:
                "Poin didapat dari setiap transaksi. Tukarkan poin kamu di menu Tukar Point dengan berbagai reward menarik.",
          ),
          InfoSectionCard(
            icon: Icons.verified_user_rounded,
            color: Color(0xffF6B91A),
            title: "Kenapa akun saya perlu diverifikasi?",
            description:
                "Verifikasi akun membantu mengamankan data kamu dan membuka akses penuh ke semua fitur GameOn.",
          ),
        ],
      ),
    );
  }
}

class _TermsPage extends StatelessWidget {
  const _TermsPage();

  @override
  Widget build(BuildContext context) {
    const paragraphStyle = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.6,
    );

    return InfoPage(
      title: "Syarat & Ketentuan",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "1. Ketentuan Umum",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Dengan menggunakan aplikasi GameOn, pengguna dianggap telah membaca, memahami, dan menyetujui seluruh syarat dan ketentuan yang berlaku.",
            style: paragraphStyle,
          ),
          SizedBox(height: 16),
          Text(
            "2. Akun Pengguna",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Pengguna bertanggung jawab penuh atas kerahasiaan PIN dan password akun. Segala aktivitas yang terjadi pada akun menjadi tanggung jawab pemilik akun.",
            style: paragraphStyle,
          ),
          SizedBox(height: 16),
          Text(
            "3. Saldo & Pembayaran",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Saldo yang sudah di top up tidak dapat ditarik kembali dalam bentuk tunai dan hanya dapat digunakan untuk transaksi di dalam aplikasi GameOn.",
            style: paragraphStyle,
          ),
          SizedBox(height: 16),
          Text(
            "4. Perubahan Ketentuan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "GameOn berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diinformasikan melalui aplikasi.",
            style: paragraphStyle,
          ),
        ],
      ),
    );
  }
}

class _ContactUsPage extends StatelessWidget {
  const _ContactUsPage();

  @override
  Widget build(BuildContext context) {
    return InfoPage(
      title: "Hubungi Kami",
      child: Column(
        children: const [
          InfoSectionCard(
            icon: Icons.chat_bubble_outline_rounded,
            color: Color(0xff2ED573),
            title: "WhatsApp - Dansen",
            description: "085249308015",
          ),
          InfoSectionCard(
            icon: Icons.chat_bubble_outline_rounded,
            color: Color(0xff2ED573),
            title: "WhatsApp - P. Aim",
            description: "082148536558",
          ),
          InfoSectionCard(
            icon: Icons.location_on_outlined,
            color: Color(0xffA855F7),
            title: "Outlet Dansen",
            description: "Jl. Danau Sentarum (Lt 1 Magnolia)",
          ),
          InfoSectionCard(
            icon: Icons.location_on_outlined,
            color: Color(0xffA855F7),
            title: "Outlet P. Aim",
            description: "Jl. Panglima Aim",
          ),
          InfoSectionCard(
            icon: Icons.public_rounded,
            color: Color(0xff46A8FF),
            title: "Media Sosial",
            description: "Instagram & TikTok: @ptkgameon",
          ),
        ],
      ),
    );
  }
}
