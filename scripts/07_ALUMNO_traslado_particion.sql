-- 07 · Conexión ALUMNO (servicio bdii). Ejecutar como script, DESPUÉS de las comprobaciones del particionado.
-- Simula el cierre de noviembre: la partición y sus dos particiones de índice pasan al tablespace histórico.
ALTER TABLE Pasajero_Viaje_Part MOVE PARTITION p_2026_11 TABLESPACE ts_renfe_hist UPDATE INDEXES;
ALTER INDEX pk_pasviaje_part REBUILD PARTITION ip_2026_11 TABLESPACE ts_renfe_hist;
ALTER INDEX ix_pasviajep_viaje REBUILD PARTITION ip_2026_11 TABLESPACE ts_renfe_hist;
