-- 08 · Medida del redo (apartado E). NO se ejecuta como script: cada sentencia sola, con Ctrl+Enter,
-- alternando las dos hojas en este orden exacto. Las lecturas van en la hoja SYSTEM (servicio free,
-- sin ALTER SESSION: V$SYSSTAT se lee desde CDB$ROOT). Entre una lectura y la siguiente, solo la acción indicada.

-- [ALUMNO] 1
CREATE TABLE redo_test AS SELECT * FROM Billete WHERE 1 = 0;

-- [SYSTEM] lectura L1
SELECT 'L1 antes sin indices' AS lectura, TO_CHAR(SYSDATE,'HH24:MI:SS') AS hora, value AS redo_bytes FROM v$sysstat WHERE name = 'redo size';

-- [ALUMNO] 2 (dos sentencias)
INSERT INTO redo_test SELECT * FROM Billete;
COMMIT;

-- [SYSTEM] lectura L2
SELECT 'L2 despues sin indices' AS lectura, TO_CHAR(SYSDATE,'HH24:MI:SS') AS hora, value AS redo_bytes FROM v$sysstat WHERE name = 'redo size';

-- [ALUMNO] 3 (vaciar y crear los mismos 5 índices que Billete)
TRUNCATE TABLE redo_test;
ALTER TABLE redo_test ADD CONSTRAINT pk_redo_test PRIMARY KEY (localizador) USING INDEX TABLESPACE ts_renfe_indices;
ALTER TABLE redo_test ADD CONSTRAINT uq_redo_test UNIQUE (localizador, tipo_billete) USING INDEX TABLESPACE ts_renfe_indices;
CREATE INDEX ix_redo_fcompra ON redo_test (f_compra) TABLESPACE ts_renfe_indices;
CREATE INDEX ix_redo_pasajero ON redo_test (dni_pasajero) TABLESPACE ts_renfe_indices;
CREATE INDEX ix_redo_taquilla ON redo_test (cod_estacion_taq, num_taquilla) TABLESPACE ts_renfe_indices;

-- [SYSTEM] lectura L3
SELECT 'L3 antes con indices' AS lectura, TO_CHAR(SYSDATE,'HH24:MI:SS') AS hora, value AS redo_bytes FROM v$sysstat WHERE name = 'redo size';

-- [ALUMNO] 4 (dos sentencias)
INSERT INTO redo_test SELECT * FROM Billete;
COMMIT;

-- [SYSTEM] lectura L4
SELECT 'L4 despues con indices' AS lectura, TO_CHAR(SYSDATE,'HH24:MI:SS') AS hora, value AS redo_bytes FROM v$sysstat WHERE name = 'redo size';

-- [ALUMNO] 5 limpieza
DROP TABLE redo_test PURGE;

-- Cálculo: (L2 - L1) / 50000 = bytes de redo por fila sin índices; (L4 - L3) / 50000 = con índices.
