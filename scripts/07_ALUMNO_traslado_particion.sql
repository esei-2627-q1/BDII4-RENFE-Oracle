-- 07 · Conexión ALUMNO (servicio bdii). Ejecutar como script, DESPUÉS de las comprobaciones del particionado.
-- Simula el cierre de noviembre: la partición y su partición del índice local pasan al tablespace histórico.
-- UPDATE INDEXES mantiene a la vez el índice global de la PK (sin él quedaría UNUSABLE)
-- y la partición del índice local, que después se reconstruye en ts_renfe_hist.
ALTER TABLE Billete_Part MOVE PARTITION p_2026_11 TABLESPACE ts_renfe_hist UPDATE INDEXES;
ALTER INDEX uq_billetep_asiento REBUILD PARTITION ip_2026_11 TABLESPACE ts_renfe_hist;
