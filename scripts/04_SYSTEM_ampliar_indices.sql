-- 04 · Conexión SYSTEM (servicio free). Ejecutar como script, DESPUÉS de capturar el "después" de la carga.
-- Amplía el máximo del archivo de índices y la cuota de ALUMNO de 256 a 512 MiB (apartado B, límites de crecimiento).
ALTER SESSION SET CONTAINER = BDII;
ALTER DATABASE DATAFILE '/opt/oracle/oradata/FREE/BDII/ts_renfe_indices01.dbf' AUTOEXTEND ON NEXT 8M MAXSIZE 512M;
ALTER USER alumno QUOTA 512M ON ts_renfe_indices;
