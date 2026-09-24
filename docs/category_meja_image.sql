-- Kolom gambar kategori meja.
-- Backend (Apimobile_model: get_booking_rooms, get_featured_categories, format_category)
-- mereferensikan kolom ini. Tanpa kolom ini, /apimobile/booking_rooms melempar
-- "Database Error 1054: Unknown column 'category_meja.category_meja_image'" sehingga
-- daftar room di halaman Booking kosong.
--
-- Jalankan sekali di database `gameon` (phpMyAdmin / mysql CLI).

ALTER TABLE `category_meja`
  ADD COLUMN `category_meja_image` VARCHAR(255) NULL DEFAULT NULL AFTER `category_meja_name`;

-- Opsional: isi gambar untuk kategori yang mau tampil di "Paket Favorit" dashboard
-- (get_featured_categories menyaring WHERE category_meja_image IS NOT NULL). Contoh:
-- UPDATE `category_meja` SET `category_meja_image` = 'reguler.png'  WHERE `category_meja_name` = 'Reguler';
-- UPDATE `category_meja` SET `category_meja_image` = 'vvip.png'     WHERE `category_meja_name` = 'VVIP';
