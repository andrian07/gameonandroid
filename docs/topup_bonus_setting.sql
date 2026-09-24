-- ============================================================================
--  TABEL topup_bonus_setting  (promo "Extra Saldo" tiap top up)
-- ----------------------------------------------------------------------------
--  Tujuan: admin bisa atur PERIODE & NOMINAL bonus top up secara fleksibel
--  lewat data, tanpa perlu ubah kode. Bisa nyimpen banyak baris (promo masa
--  lalu/depan sekaligus) - yang dipakai app & dipakai buat nge-kredit bonus
--  cuma baris yang lagi AKTIF (is_active=1 dan tanggal sekarang ada di antara
--  start_date & end_date).
--
--  Dipakai oleh (BELUM dibuat, backend perlu implementasi):
--    - POST /apimobile/topup_bonus_info  -> baca baris aktif, dipakai app
--      customer buat nampilin banner info promo di halaman Top Up.
--    - Konfirmasi top up di kasir/billing_api -> saat top up disetujui &
--      tanggal masuk periode aktif, saldo yang di-kredit = nominal top up +
--      bonus_amount (dicatat terpisah di histori kalau perlu, mis. 2 baris
--      customer_history: satu "Top Up Saldo", satu "Bonus Top Up Promo").
-- ============================================================================

CREATE TABLE IF NOT EXISTS `topup_bonus_setting` (
  `topup_bonus_setting_id` INT(11) NOT NULL AUTO_INCREMENT,
  `title`             VARCHAR(150) NOT NULL,               -- nama promo, mis. "Extra Saldo Sep-Okt 2026"
  `description`       VARCHAR(255) NULL,                    -- teks yang tampil ke customer di app
  `start_date`        DATE NOT NULL,
  `end_date`          DATE NOT NULL,
  `bonus_amount`      INT(11) NOT NULL DEFAULT 0,            -- nominal bonus flat (Rupiah) per top up
  `min_topup_amount`  INT(11) NOT NULL DEFAULT 0,            -- 0 = tanpa syarat minimal top up
  `is_active`         TINYINT(1) NOT NULL DEFAULT 1,         -- saklar manual on/off, di luar cek periode
  `branch`            INT(11) NOT NULL DEFAULT 1,            -- 0/NULL kalau mau dianggap berlaku semua cabang
  `created_by`        VARCHAR(100) NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`topup_bonus_setting_id`),
  KEY `idx_period_active` (`is_active`, `start_date`, `end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Query yang backend pakai buat ambil promo yang lagi aktif SEKARANG
-- (dipanggil dari endpoint /apimobile/topup_bonus_info & saat konfirmasi topup):
--
--   SELECT * FROM topup_bonus_setting
--    WHERE is_active = 1
--      AND CURDATE() BETWEEN start_date AND end_date
--    ORDER BY topup_bonus_setting_id DESC
--    LIMIT 1;

-- ----------------------------------------------------------------------------
--  Contoh isi: promo sesuai request - September s.d. Oktober 2026, bonus
--  flat Rp15.000 untuk top up minimal Rp50.000.
-- ----------------------------------------------------------------------------
INSERT INTO `topup_bonus_setting`
  (`title`, `description`, `start_date`, `end_date`, `bonus_amount`, `min_topup_amount`, `is_active`, `created_by`)
VALUES
  ('Extra Saldo September - Oktober 2026',
   'Top up minimal Rp50.000 dapat extra saldo Rp15.000! Berlaku 1 September - 31 Oktober 2026.',
   '2026-09-01', '2026-10-31', 15000, 50000, 1, 'admin');

-- ----------------------------------------------------------------------------
--  Contoh bentuk JSON yang diharapkan dikirim endpoint /apimobile/topup_bonus_info
--  (endpoint ini BELUM ada - perlu dibuat backend). Kalau tidak ada promo
--  aktif, "result" dikirim null - app otomatis sembunyikan banner-nya.
-- ----------------------------------------------------------------------------
--  {
--    "code": 200,
--    "result": {
--      "title": "Extra Saldo September - Oktober 2026",
--      "description": "Top up minimal Rp50.000 dapat extra saldo Rp15.000! Berlaku 1 September - 31 Oktober 2026.",
--      "bonus_amount": 15000,
--      "min_topup_amount": 50000,
--      "start_date": "2026-09-01",
--      "end_date": "2026-10-31"
--    }
--  }
--  Kalau belum/tidak ada promo aktif: {"code": 200, "result": null}
-- ============================================================================
