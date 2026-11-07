-- 01 · Conexión SYSTEM (servicio free). Ejecutar como script.
-- Crea los tablespaces de datos e índices, da cuota a ALUMNO y lo pone a usar ts_renfe_datos.
-- El de índices se crea con máximo 256 MiB, como en la práctica; el script 04 lo amplía a 512 MiB.
ALTER SESSION SET CONTAINER = BDII;

CREATE SMALLFILE TABLESPACE ts_renfe_datos
  DATAFILE '/opt/oracle/oradata/FREE/BDII/ts_renfe_datos01.dbf'
  SIZE 64M AUTOEXTEND ON NEXT 16M MAXSIZE 512M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

CREATE SMALLFILE TABLESPACE ts_renfe_indices
  DATAFILE '/opt/oracle/oradata/FREE/BDII/ts_renfe_indices01.dbf'
  SIZE 32M AUTOEXTEND ON NEXT 8M MAXSIZE 256M
  EXTENT MANAGEMENT LOCAL AUTOALLOCATE
  SEGMENT SPACE MANAGEMENT AUTO;

ALTER USER alumno QUOTA 512M ON ts_renfe_datos;
ALTER USER alumno QUOTA 256M ON ts_renfe_indices;
ALTER USER alumno DEFAULT TABLESPACE ts_renfe_datos;
