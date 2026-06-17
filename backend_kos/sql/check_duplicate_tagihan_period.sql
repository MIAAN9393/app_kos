SELECT
  t.kontrak_id,
  t.periode_awal,
  t.periode_akhir,
  COUNT(DISTINCT t.id) AS jumlah,
  GROUP_CONCAT(DISTINCT t.id ORDER BY t.id) AS tagihan_ids
FROM tagihan t
INNER JOIN tagihan_item ti
  ON ti.tagihan_id = t.id
  AND ti.tipe = 'sewa'
WHERE t.lifecycle <> 'cancelled'
GROUP BY t.kontrak_id, t.periode_awal, t.periode_akhir
HAVING COUNT(DISTINCT t.id) > 1;
