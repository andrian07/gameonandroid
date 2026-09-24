-- ============================================================================
--  CONTOH: "POTONG SALDO" (saldo member berkurang)
-- ----------------------------------------------------------------------------
--  Dipakai untuk menguji tampilan di app:
--    - Halaman "Riwayat Aktivitas"  -> POST /apimobile/history
--    - Kartu riwayat ditekan         -> popup detail (_HistoryDetailSheet)
--    - Lonceng / halaman Notifikasi   -> POST /apimobile/notifications
--
--  CATATAN: nama tabel & kolom di bawah adalah ASUMSI berdasarkan field yang
--  dikirim API. Sesuaikan dengan skema database gameon yang sebenarnya.
--  Ganti  @customer_id  dengan id member yang dipakai untuk login di app.
--
--  UPDATE 2026-09: /apimobile/history sekarang membaca data ASLI dari:
--    - branch_transaction        (sesi main: start/end/duration/table/promo)
--    - branch_transaction_cafe + branch_transaction_cafe_detail (pesanan cafe)
--    - history_saldo             (hanya baris NON-payment: top up / refund)
--    - customer_point_history    (mutasi point)
--  Lihat gameon/application/models/Apimobile_model.php::get_history().
--  branch_transaction* diisi otomatis oleh billing_api (receive_branch_transaction*),
--  jadi Bagian 2 & 3 di bawah TIDAK perlu di-INSERT manual - biarkan sebagai
--  referensi bentuk data saja.
-- ============================================================================

SET @customer_id      = 12;            -- id member target
SET @potong           = 50000;        -- nominal yang dipotong (Rupiah)
SET @keterangan       = 'Pembayaran booking PS5 Reguler 2 Jam';
SET @waktu            = NOW();


-- ----------------------------------------------------------------------------
-- 1) KURANGI SALDO DI TABEL MEMBER
-- ----------------------------------------------------------------------------
UPDATE customer
   SET customer_balance = customer_balance - @potong
 WHERE customer_id = @customer_id;


-- ----------------------------------------------------------------------------
-- 2) CATAT DI RIWAYAT / MUTASI  (sumber data POST /apimobile/history)
--
--    Kolom penting yang dibaca app (lihat transaction_list.dart):
--      type       : 'saldo'  atau 'point'
--      movement   : 'IN'     atau 'OUT'   -> 'OUT' = potong saldo
--      amount     : angka positif (tanda +/- ditentukan dari movement)
--      description : teks yang tampil di kartu & popup detail
--      created_at  : dipakai untuk label tanggal/jam
-- ----------------------------------------------------------------------------
INSERT INTO customer_history
    (customer_id, type,    movement, amount,   description,    created_at)
VALUES
    (@customer_id, 'saldo', 'OUT',    @potong,  @keterangan,    @waktu);


-- ----------------------------------------------------------------------------
-- 3) KIRIM NOTIFIKASI  (sumber data POST /apimobile/notifications)
--
--    Kolom yang dibaca app (lihat models/notificationModel.dart):
--      type       : 'booking' | 'topup' | 'promo' | 'point' | 'tournament'
--                   | 'verification' | 'cafe' | 'reward'
--                   -> untuk potong saldo pakai 'topup' (ikon dompet, biru)
--      title      : judul tebal
--      message    : isi notifikasi
--      is_read    : 0 = belum dibaca (muncul titik ungu + badge lonceng)
--      created_at : dipakai untuk label waktu relatif ("5 menit lalu")
-- ----------------------------------------------------------------------------
INSERT INTO notifications
    (customer_id,  type,   title,             message,                                                        is_read, created_at)
VALUES
    (@customer_id, 'topup', 'Saldo Terpotong', CONCAT('Saldo kamu terpotong Rp', FORMAT(@potong, 0),
                                                      ' untuk ', @keterangan, '.'),                            0,       @waktu);


-- ============================================================================
--  CONTOH BENTUK JSON YANG DITERIMA APP
-- ============================================================================
--
--  A. POST /apimobile/history
--  ---------------------------------------------------------------------------
--  {
--    "code": 200,
--    "result": [
--      {
--        "type": "saldo",
--        "movement": "OUT",
--        "amount": 50000,
--        "description": "Pembayaran booking PS5 Reguler 2 Jam",
--        "created_at": "2026-09-02 15:30:00"
--      }
--    ]
--  }
--
--  Tampil di app:
--    Kartu   : "Pembayaran booking PS5 Reguler 2 Jam"   -Rp50.000  (merah)
--    Popup   : Jenis  = Saldo
--              Tipe   = Saldo Keluar
--              Jumlah = Rp50.000
--              Waktu  = 2 Sep 2026, 15:30
--
--
--  B. POST /apimobile/notifications
--  ---------------------------------------------------------------------------
--  {
--    "code": 200,
--    "result": [
--      {
--        "id": 91,
--        "type": "topup",
--        "title": "Saldo Terpotong",
--        "message": "Saldo kamu terpotong Rp50.000 untuk Pembayaran booking PS5 Reguler 2 Jam.",
--        "is_read": 0,
--        "created_at": "2026-09-02 15:30:00"
--      }
--    ]
--  }
--
--  Tampil di app:
--    Ikon dompet biru, judul "Saldo Terpotong", titik ungu (belum dibaca),
--    badge angka di lonceng header bertambah 1.
-- ============================================================================



-- ############################################################################
--  BAGIAN 2: TRANSAKSI BILLING (sesi main per unit / meja)
-- ----------------------------------------------------------------------------
--  Sumber aslinya billing_api di cabang, lalu disinkron ke gameon. Contoh di
--  bawah: 1 sesi main PS5 VVIP selama 2 jam yang dibayar pakai saldo.
-- ############################################################################

SET @billing_customer_id = 12;
SET @billing_unit        = 'PS5 VVIP 2';   -- meja / unit / ruangan tempat main
SET @billing_category    = 'PS5 VVIP';
SET @billing_start       = '2026-09-02 13:00:00';
SET @billing_end         = '2026-09-02 15:00:00';
SET @billing_minutes     = 120;                         -- lama main (menit)
SET @billing_promo       = 'Happy Hour 20%';            -- NULL kalau tanpa promo
SET @billing_rate        = 20000;                       -- tarif per jam
SET @billing_total       = @billing_rate * @billing_minutes / 60;   -- 40.000
SET @billing_invoice     = 'INV-20260902-001';          -- kode struk billing


-- 1) CATAT TRANSAKSI BILLING (tabel hasil sinkron dari billing_api cabang)
INSERT INTO billing_transaction
    (customer_id,          branch_code, invoice_code,     unit_name,     category_name,     start_time,     end_time,     duration_minutes, promo_name,     rate_per_hour, total_amount,   payment_method, created_at)
VALUES
    (@billing_customer_id, 'CB01',      @billing_invoice, @billing_unit, @billing_category, @billing_start, @billing_end, @billing_minutes, @billing_promo, @billing_rate, @billing_total, 'saldo',        @billing_end);

-- 2) POTONG SALDO MEMBER
UPDATE customer
   SET customer_balance = customer_balance - @billing_total
 WHERE customer_id = @billing_customer_id;

-- 3) MASUK KE RIWAYAT AKTIVITAS (POST /apimobile/history)
--    Kolom extra (start_time, end_time, duration_minutes, promo, unit_name)
--    hanya untuk baris hasil sinkron billing -> muncul di kartu "Sesi Main"
--    pada popup detail. Kode struk di dalam ( ) otomatis DISEMBUNYIKAN app.
--    Catatan: duration_minutes boleh dikosongkan kalau start_time & end_time
--    ada -> app menghitung sendiri selisihnya.
INSERT INTO customer_history
    (customer_id,          type,    movement, amount,         description,                                                    start_time,      end_time,      duration_minutes, promo,          unit_name,      created_at)
VALUES
    (@billing_customer_id, 'saldo', 'OUT',    @billing_total, CONCAT('Main ', @billing_category, ' (', @billing_invoice, ')'), @billing_start,  @billing_end,  @billing_minutes, @billing_promo, @billing_unit,  @billing_end);

-- 4) NOTIFIKASI (type 'booking' -> ikon kalender)
INSERT INTO notifications
    (customer_id,          type,      title,               message,                                                                            is_read, created_at)
VALUES
    (@billing_customer_id, 'booking', 'Sesi Main Selesai', CONCAT('Sesi ', @billing_unit, ' selama ', @billing_minutes/60,
                                                                  ' jam selesai. Saldo terpotong Rp', FORMAT(@billing_total, 0), '.'),         0,       @billing_end);

--  JSON di POST /apimobile/history:
--  {
--    "type": "saldo", "movement": "OUT", "amount": 40000,
--    "description": "Main PS5 VVIP (INV-20260902-001)",
--    "start_time": "2026-09-02 13:00:00", "end_time": "2026-09-02 15:00:00",
--    "duration_minutes": 120, "promo": "Happy Hour 20%", "unit_name": "PS5 VVIP 2",
--    "created_at": "2026-09-02 15:00:00"
--  }
--  Kartu riwayat : "Main PS5 VVIP"   -Rp40.000 (merah)   -- kode struk disembunyikan
--  Popup detail  :
--    [ SALDO KELUAR ]  - Rp40.000  (merah; kalau IN jadi hijau "+ Rp..")
--    Main PS5 VVIP
--    +------------------- Sesi Main -------------------+
--    | Mulai 13:00  --2 Jam-->  Selesai 15:00          |
--    | 2 Sep 2026                                      |
--    | Ruangan / Unit : PS5 VVIP 2                     |
--    | Promo          : Happy Hour 20%  (atau "Tanpa promo") |
--    +------------------------------------------------+
--    Rincian Transaksi: Jenis=Saldo, Jumlah=Rp40.000, Tanggal=2 Sep 2026, Jam=15:00



-- ############################################################################
--  BAGIAN 3: TRANSAKSI CAFE (pesanan makanan / minuman)
-- ----------------------------------------------------------------------------
--  Contoh: 1 order berisi 2x Kopi Susu (@10.000) + 1x Nachos (@17.000).
-- ############################################################################

SET @cafe_customer_id = 12;
SET @cafe_time        = '2026-09-02 14:10:00';
SET @cafe_total       = 2*10000 + 1*17000;              -- 37.000
SET @cafe_code        = 'ORD-20260902-014';             -- kode order cafe

-- 1) HEADER ORDER
INSERT INTO cafe_order
    (customer_id,       branch_code, order_code, total_amount, payment_method, status,   created_at)
VALUES
    (@cafe_customer_id, 'CB01',      @cafe_code,  @cafe_total,   'saldo',        'paid',   @cafe_time);

SET @cafe_order_id = LAST_INSERT_ID();

-- 2) DETAIL ITEM ORDER
INSERT INTO cafe_order_item
    (order_id,       item_name,    qty, unit_price, subtotal)
VALUES
    (@cafe_order_id, 'Kopi Susu',  2,   10000,      20000),
    (@cafe_order_id, 'Nachos',     1,   17000,      17000);

-- 3) POTONG SALDO MEMBER
UPDATE customer
   SET customer_balance = customer_balance - @cafe_total
 WHERE customer_id = @cafe_customer_id;

-- 4) MASUK KE RIWAYAT AKTIVITAS (POST /apimobile/history)
--    Kode order ditaruh di dalam ( ) -> app otomatis menyembunyikannya,
--    daftar item tetap tampil.
INSERT INTO customer_history
    (customer_id,       type,    movement, amount,      description,                                              created_at)
VALUES
    (@cafe_customer_id, 'saldo', 'OUT',    @cafe_total, CONCAT('Pesanan Cafe: 2 Kopi Susu, 1 Nachos (', @cafe_code, ')'), @cafe_time);

-- 5) NOTIFIKASI (type 'cafe' -> ikon gelas kopi, ungu)
INSERT INTO notifications
    (customer_id,       type,   title,               message,                                                                is_read, created_at)
VALUES
    (@cafe_customer_id, 'cafe', 'Pesanan Cafe Dibayar', CONCAT('Pesanan cafe kamu Rp', FORMAT(@cafe_total, 0),
                                                              ' berhasil dibayar dari saldo.'),                                0,       @cafe_time);

--  JSON di POST /apimobile/history:
--  {
--    "type": "saldo", "movement": "OUT", "amount": 37000,
--    "description": "Pesanan Cafe: 2 Kopi Susu, 1 Nachos (ORD-20260902-014)",
--    "created_at": "2026-09-02 14:10:00"
--  }
--  Kartu riwayat : "Pesanan Cafe: 2 Kopi Susu, 1 Nachos"   -Rp37.000   (kode order disembunyikan)
--  Popup detail  : Jenis=Saldo, Tipe=Saldo Keluar, Jumlah=Rp37.000, Waktu=2 Sep 2026, 14:10
--
--  Kalau nanti mau tampilkan rincian item per order, siapkan endpoint
--  detail tersendiri (mis. POST /apimobile/cafe_order dengan order_id) yang
--  membaca cafe_order + cafe_order_item.
-- ============================================================================



-- ############################################################################
--  BAGIAN 4: ATURAN NOTIFIKASI OTOMATIS
-- ----------------------------------------------------------------------------
--  SETIAP kali ada mutasi (baris baru di customer_history), buat juga 1 baris
--  di tabel `notifications` untuk member tsb. Jadi member selalu dapat notif:
--    - saldo terpotong  (movement OUT, type 'saldo')
--    - saldo masuk       (movement IN,  type 'saldo')  -> top up berhasil
--    - dapat point       (movement IN,  type 'point')
--    - point terpakai    (movement OUT, type 'point')
--
--  Paling praktis: bikin TRIGGER AFTER INSERT di customer_history (contoh di
--  bawah), atau panggil INSERT notifikasi manual di kode tiap transaksi.
-- ############################################################################

-- ------------------------------------------------------------------ 4a. SALDO MASUK (TOP UP)
SET @tu_customer_id = 12;
SET @tu_amount      = 100000;
SET @tu_time        = '2026-09-02 12:00:00';

UPDATE customer
   SET customer_balance = customer_balance + @tu_amount
 WHERE customer_id = @tu_customer_id;

INSERT INTO customer_history
    (customer_id,     type,    movement, amount,     description,        created_at)
VALUES
    (@tu_customer_id, 'saldo', 'IN',     @tu_amount, 'Top Up Saldo',     @tu_time);

INSERT INTO notifications
    (customer_id,     type,    title,             message,                                                            is_read, created_at)
VALUES
    (@tu_customer_id, 'topup', 'Top Up Berhasil', CONCAT('Saldo kamu bertambah Rp', FORMAT(@tu_amount, 0), '.'),      0,       @tu_time);

--  JSON /apimobile/history : {"type":"saldo","movement":"IN","amount":100000,"description":"Top Up Saldo", ...}
--  Kartu riwayat  : "Top Up Saldo"  +Rp100.000  (hijau)
--  Notifikasi     : ikon dompet biru, "Top Up Berhasil"


-- ------------------------------------------------------------------ 4b. DAPAT POINT
SET @pt_customer_id = 12;
SET @pt_amount      = 100;                       -- jumlah point yang didapat
SET @pt_time        = '2026-09-02 15:05:00';
SET @pt_sumber      = 'sesi main PS5 VVIP';       -- asal point

UPDATE customer
   SET customer_point = customer_point + @pt_amount
 WHERE customer_id = @pt_customer_id;

INSERT INTO customer_history
    (customer_id,     type,    movement, amount,     description,                                 created_at)
VALUES
    (@pt_customer_id, 'point', 'IN',     @pt_amount, CONCAT('Point dari ', @pt_sumber),           @pt_time);

INSERT INTO notifications
    (customer_id,     type,    title,           message,                                                                       is_read, created_at)
VALUES
    (@pt_customer_id, 'point', 'Point Bertambah', CONCAT('Kamu dapat ', @pt_amount, ' point dari ', @pt_sumber, '.'),          0,       @pt_time);

--  JSON /apimobile/history : {"type":"point","movement":"IN","amount":100,"description":"Point dari sesi main PS5 VVIP", ...}
--  Kartu riwayat  : "Point dari sesi main PS5 VVIP"  +100 pt  (hijau)
--  Notifikasi     : ikon kado ungu, "Point Bertambah"


-- ------------------------------------------------------------------ 4c. CONTOH TRIGGER (opsional, biar otomatis)
--  Mapping type mutasi -> type notifikasi:
--    saldo IN  -> 'topup'   | saldo OUT -> 'topup'
--    point IN  -> 'point'   | point OUT -> 'point'
--
--  DELIMITER $$
--  CREATE TRIGGER trg_history_to_notif
--  AFTER INSERT ON customer_history
--  FOR EACH ROW
--  BEGIN
--    DECLARE v_title VARCHAR(60);
--    DECLARE v_msg   VARCHAR(255);
--
--    IF NEW.type = 'saldo' AND NEW.movement = 'IN' THEN
--      SET v_title = 'Top Up Berhasil';
--      SET v_msg   = CONCAT('Saldo kamu bertambah Rp', FORMAT(NEW.amount, 0), '.');
--    ELSEIF NEW.type = 'saldo' AND NEW.movement = 'OUT' THEN
--      SET v_title = 'Saldo Terpotong';
--      SET v_msg   = CONCAT('Saldo kamu terpotong Rp', FORMAT(NEW.amount, 0),
--                           ' untuk ', NEW.description, '.');
--    ELSEIF NEW.type = 'point' AND NEW.movement = 'IN' THEN
--      SET v_title = 'Point Bertambah';
--      SET v_msg   = CONCAT('Kamu dapat ', NEW.amount, ' point. (', NEW.description, ')');
--    ELSE
--      SET v_title = 'Point Terpakai';
--      SET v_msg   = CONCAT(NEW.amount, ' point kamu terpakai. (', NEW.description, ')');
--    END IF;
--
--    INSERT INTO notifications (customer_id, type, title, message, is_read, created_at)
--    VALUES (NEW.customer_id,
--            IF(NEW.type = 'point', 'point', 'topup'),
--            v_title, v_msg, 0, NEW.created_at);
--  END$$
--  DELIMITER ;
-- ============================================================================
