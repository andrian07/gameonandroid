-- Kolom untuk verifikasi email member.
-- Dipakai endpoint backend:
--   POST /apimobile/request_verification  -> kirim link verifikasi ke email customer
--   GET  /apimobile/verify_email?token=.. -> dibuka dari email, menandai terverifikasi
--
-- Jalankan sekali di database `gameon` (phpMyAdmin / mysql CLI) SEBELUM memakai fitur.

ALTER TABLE `ms_customer`
  ADD COLUMN `customer_verification_token`   VARCHAR(64) NULL DEFAULT NULL AFTER `customer_verification`,
  ADD COLUMN `customer_verification_sent_at` DATETIME    NULL DEFAULT NULL AFTER `customer_verification_token`;
