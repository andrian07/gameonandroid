class ApiUrl {
  /// Ubah base URL di sini saja untuk mengganti target API (local/staging/production).
  // Development (lokal) - backend CodeIgniter di XAMPP htdocs/gameon, DB `gameon` lokal (root, no password).
  // 10.0.2.2 = alias host Mac dari dalam Android Emulator (localhost di situ merujuk ke emulator sendiri).
  //static const String baseUrl = "http://10.0.2.2/gameon";
  // Staging
  static const String baseUrl = "http://staging.gameonstation.com";
  // Production
  //static const String baseUrl = "https://gameonstation.com";

  static const String login = "/apimobile/login";

  static const String register = "/apimobile/register";

  static const String profile = "/apimobile/profile";

  static const String customerDetail = "/apimobile/customer_detail";

  static const String updateProfile = "/apimobile/update_profile";

  static const String updatePassword = "/apimobile/update_password";

  static const String requestVerification = "/apimobile/request_verification";

  static const String customerTime = "/apimobile/customer_time";

  static const String customerTimeHistory = "/apimobile/customer_time_history";

  static const String updatePin = "/apimobile/update_pin";

  static const String roomCategories = "/apimobile/room_categories";

  static const String topup = "/apimobile/topup";

  // Info promo "Extra Saldo" yang lagi aktif (periode & nominal bonus diatur
  // fleksibel lewat tabel topup_bonus_setting, lihat docs/topup_bonus_setting.sql).
  static const String topupBonusInfo = "/apimobile/topup_bonus_info";

  static const String booking = "/apimobile/booking";

  static const String bookingRooms = "/apimobile/booking_rooms";

  static const String bookedSlots = "/apimobile/booked_slots";

  static const String history = "/apimobile/history";

  static const String notifications = "/apimobile/notifications";

  static const String notificationRead = "/apimobile/notification_read";

  static const String notificationDelete = "/apimobile/notification_delete";

  static const String fcmToken = "/apimobile/fcm_token";

  static const String rewardCategories = "/apimobile/reward_categories";
  static const String rewards = "/apimobile/rewards";
  static const String redeemReward = "/apimobile/redeem_reward";
  static const String rewardRedemptions = "/apimobile/reward_redemptions";

  // Konfirmasi PIN pembayaran (kasir bayar Potong Saldo pakai member)
  static const String pendingApprovals = "/apimobile/pending_approvals";
  static const String respondApproval = "/apimobile/respond_approval";
}
