-- 09 · Pruebas del apartado F con una cuenta temporal. No toca DEFAULT, SYSTEM ni ALUMNO.

-- PARTE 1 · Conexión SYSTEM (servicio free), como script
ALTER SESSION SET CONTAINER = BDII;
CREATE PROFILE perfil_prueba_2 LIMIT SESSIONS_PER_USER 2;
CREATE USER usr_prueba IDENTIFIED BY "Prueba_2026_x"
  DEFAULT TABLESPACE users QUOTA 1M ON users PROFILE perfil_prueba_2;
GRANT CREATE SESSION, CREATE TABLE TO usr_prueba;

-- PARTE 2 · Límite de sesiones (SQL Developer para VS Code)
-- Crear tres conexiones iguales: usr_prueba_1, usr_prueba_2 y usr_prueba_3
-- (host localhost, puerto 1521, servicio bdii, usuario usr_prueba, contraseña Prueba_2026_x).
-- Abrir la 1 y la 2: entran. Abrir la 3: debe fallar con ORA-02391. Hacer captura.

-- PARTE 3 · Cuota, en una hoja de usr_prueba_1, como script
CREATE TABLE prueba_cuota (id NUMBER, texto VARCHAR2(200));
INSERT INTO prueba_cuota SELECT level, RPAD('x',200,'x') FROM dual CONNECT BY level <= 50000;
-- Debe fallar con ORA-01536: space quota exceeded for tablespace 'USERS'
SELECT tablespace_name, bytes, max_bytes FROM user_ts_quotas;

-- PARTE 4 · Limpieza. Desconectar antes TODAS las conexiones usr_prueba (si no, ORA-01940).
-- Conexión SYSTEM, como script:
ALTER SESSION SET CONTAINER = BDII;
DROP USER usr_prueba CASCADE;
DROP PROFILE perfil_prueba_2;
