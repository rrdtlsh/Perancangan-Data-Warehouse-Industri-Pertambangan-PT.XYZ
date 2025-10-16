-- 1. Validasi Skema (Contoh: Cek keberadaan tabel)
PRINT '--- 1. Schema Validation ---';
SELECT CASE WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'fact' AND TABLE_NAME = 'FactProduction') 
THEN 'SUCCESS: Table fact.FactProduction exists.' 
ELSE 'FAIL: Table fact.FactProduction NOT FOUND.' END AS TestResult;
GO

-- 2. Validasi Integritas (Contoh: Cek data yatim/orphan)
PRINT '--- 2. Foreign Key Integrity Validation ---';
SELECT CASE WHEN COUNT(*) = 0 
THEN 'SUCCESS: No orphan records found in FactProduction.' 
ELSE 'FAIL: Found ' + CAST(COUNT(*) AS VARCHAR) + ' orphan records.' END AS TestResult
FROM fact.FactProduction fp
LEFT JOIN dim.DimSite ds ON fp.site_key = ds.site_key
WHERE ds.site_key IS NULL;
GO

-- 3. Validasi Agregat (Contoh: Cek jumlah data sesuai README)
PRINT '--- 3. Aggregate Validation ---';
SELECT CASE WHEN COUNT(*) = 830 
THEN 'SUCCESS: DimTime record count is correct (830).' 
ELSE 'FAIL: DimTime record count is ' + CAST(COUNT(*) AS VARCHAR) + ', expected 830.' END AS TestResult
FROM dim.DimTime;
GO