ALTER TABLE tagihan
  ADD COLUMN public_token VARCHAR(100) UNIQUE NULL AFTER kode_tagihan;

ALTER TABLE kontrak
  ADD COLUMN public_token VARCHAR(100) UNIQUE NULL AFTER kode_kontrak;
