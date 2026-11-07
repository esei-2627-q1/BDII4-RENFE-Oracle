-- 05 · Conexión SYSTEM (servicio free). Ejecutar como script, antes del particionado.
ALTER SESSION SET CONTAINER = BDII;

CREATE SMALLFILE TABLESPACE ts_renfe_hist
  DATAFILE '/opt/oracle/oradata/FREE/BDII/ts_renfe_hist01.dbf'
  SIZE 16M AUTOEXTEND ON NEXT 8M MAXSIZE 128M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

ALTER USER alumno QUOTA 128M ON ts_renfe_hist;
