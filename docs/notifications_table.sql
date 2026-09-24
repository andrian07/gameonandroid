-- ============================================================================
--  TABEL notifications  (dipakai POST /apimobile/notifications)
-- ----------------------------------------------------------------------------
--  Diisi lewat Apimobile_model::add_notification() / Api_model::_add_notification()
--  di tiap kejadian: top up, potong saldo, point bertambah, booking, tukar reward.
--
--  Kolom `data` = JSON detail bebas -> ditampilkan app saat notifikasi diklik
--  (mis. {"Jumlah":"Rp100.000","Metode":"Cash","Status":"Menunggu"}).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `notifications` (
  `notification_id` INT(11) NOT NULL AUTO_INCREMENT,
  `customer_id`     INT(11) NOT NULL,
  `type`            VARCHAR(30)  NOT NULL DEFAULT 'info',   -- topup|saldo|point|booking|reward|info
  `title`           VARCHAR(150) NOT NULL,
  `message`         VARCHAR(500) NOT NULL,
  `data`            TEXT NULL,                              -- JSON key-value detail
  `ref_type`        VARCHAR(40) NULL,                       -- TopupRequest|BookingRequest|Payment|...
  `ref_id`          VARCHAR(60) NULL,
  `is_read`         TINYINT(1)  NOT NULL DEFAULT 0,
  `created_at`      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `idx_cust_created` (`customer_id`, `created_at`),
  KEY `idx_cust_unread`  (`customer_id`, `is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Contoh baris:
-- INSERT INTO notifications (customer_id, type, title, message, data, ref_type, ref_id)
-- VALUES (12, 'topup', 'Top Up Berhasil',
--         'Saldo kamu bertambah Rp100.000.',
--         '{"Jumlah":"Rp100.000","Invoice":"INV/02/0900070"}',
--         'TopupRequest', '45');

-- ----------------------------------------------------------------------------
--  FCM token perangkat (buat kirim PUSH notification via Firebase).
--  Diisi lewat POST /apimobile/fcm_token (body: {token}) -> save_fcm_token().
-- ----------------------------------------------------------------------------
ALTER TABLE `ms_customer`
  ADD COLUMN IF NOT EXISTS `fcm_token` VARCHAR(255) NULL AFTER `customer_pass`,
  ADD COLUMN IF NOT EXISTS `fcm_token_updated_at` DATETIME NULL AFTER `fcm_token`;
