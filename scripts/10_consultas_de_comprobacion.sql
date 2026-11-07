-- 10 · Consultas para comparar con la memoria. Cada una sola, con Ctrl+Enter
-- (la extensión de VS Code solo muestra la tabla de resultados de la primera consulta de un script).

-- ===== [ALUMNO] Apartado B =====
SELECT table_name, tablespace_name, segment_created FROM user_tables ORDER BY table_name;
SELECT index_name, table_name, tablespace_name, status FROM user_indexes ORDER BY table_name, index_name;
SELECT segment_name, segment_type, tablespace_name, bytes, blocks, extents FROM user_segments ORDER BY tablespace_name, segment_type, segment_name;
SELECT 'PASAJERO' AS tabla, COUNT(*) AS filas FROM Pasajero UNION ALL SELECT 'BILLETE', COUNT(*) FROM Billete UNION ALL SELECT 'VIAJE', COUNT(*) FROM Viaje UNION ALL SELECT 'PASAJERO_VIAJE', COUNT(*) FROM Pasajero_Viaje UNION ALL SELECT 'RECLAMACION', COUNT(*) FROM Reclamacion;

-- ===== [SYSTEM] Apartado B (antes: ALTER SESSION SET CONTAINER = BDII;) =====
SELECT tablespace_name, block_size, status, contents, extent_management, segment_space_management FROM dba_tablespaces ORDER BY 1;
SELECT tablespace_name, file_name, ROUND(bytes/1048576,2) AS mib, autoextensible, ROUND(maxbytes/1048576,2) AS max_mib, ROUND(increment_by*8192/1048576,2) AS next_mib FROM dba_data_files WHERE tablespace_name LIKE 'TS_RENFE%';
SELECT tablespace_name, bytes, max_bytes FROM dba_ts_quotas WHERE username = 'ALUMNO' ORDER BY 1;
SELECT tablespace_name, COUNT(*) AS extensiones, SUM(blocks) AS bloques, ROUND(SUM(bytes)/1048576,2) AS mib FROM dba_extents WHERE owner = 'ALUMNO' AND tablespace_name IN ('TS_RENFE_DATOS','TS_RENFE_INDICES') GROUP BY tablespace_name ORDER BY 1;
SELECT tablespace_name, segment_name, extent_id, file_id, block_id, blocks, bytes FROM dba_extents WHERE owner = 'ALUMNO' AND segment_name IN ('BILLETE','IX_BILLETE_FCOMPRA') ORDER BY segment_name, extent_id;

-- ===== [ALUMNO] Apartado C =====
SELECT partition_position, partition_name, tablespace_name, high_value FROM user_tab_partitions WHERE table_name = 'PASAJERO_VIAJE_PART' ORDER BY partition_position;
SELECT 'P_2026_11' AS particion, COUNT(*) AS filas FROM Pasajero_Viaje_Part PARTITION (p_2026_11) UNION ALL SELECT 'P_2026_12', COUNT(*) FROM Pasajero_Viaje_Part PARTITION (p_2026_12) UNION ALL SELECT 'P_2027_01', COUNT(*) FROM Pasajero_Viaje_Part PARTITION (p_2027_01) UNION ALL SELECT 'P_2027_02', COUNT(*) FROM Pasajero_Viaje_Part PARTITION (p_2027_02) UNION ALL SELECT 'P_FUTURO', COUNT(*) FROM Pasajero_Viaje_Part PARTITION (p_futuro);
SELECT segment_name, partition_name, segment_type, tablespace_name, bytes, extents FROM user_segments WHERE segment_name IN ('PASAJERO_VIAJE_PART','PK_PASVIAJE_PART','IX_PASVIAJEP_VIAJE') ORDER BY segment_name, partition_name;
EXPLAIN PLAN FOR SELECT COUNT(*) FROM Pasajero_Viaje_Part WHERE fecha_salida >= DATE '2026-12-01' AND fecha_salida < DATE '2027-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +PARTITION'));
SELECT index_name, partition_name, tablespace_name, status FROM user_ind_partitions WHERE index_name IN ('PK_PASVIAJE_PART','IX_PASVIAJEP_VIAJE') ORDER BY index_name, partition_position;

-- ===== [SYSTEM] Apartados D, E y F (en CDB$ROOT, sin ALTER SESSION) =====
SELECT name, display_value FROM v$parameter WHERE name IN ('memory_target','memory_max_target','sga_target','sga_max_size','pga_aggregate_target','pga_aggregate_limit','db_cache_size','shared_pool_size','large_pool_size','log_buffer','processes','sessions') ORDER BY name;
SELECT con_id, name, ROUND(value/1048576,2) AS mib FROM v$sga ORDER BY con_id, name;
SELECT con_id, name, ROUND(value/1048576,2) AS mib FROM v$pgastat WHERE name IN ('total PGA allocated','maximum PGA allocated') ORDER BY con_id, name;
SELECT name, open_mode, log_mode FROM v$database;
SELECT group#, thread#, sequence#, ROUND(bytes/1048576,2) AS mib_por_miembro, members, status, archived FROM v$log ORDER BY thread#, group#;
SELECT group#, member FROM v$logfile ORDER BY group#;
SELECT resource_name, current_utilization, max_utilization, limit_value FROM v$resource_limit WHERE resource_name IN ('processes','sessions');
