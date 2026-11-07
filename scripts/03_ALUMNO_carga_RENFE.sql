-- ==============================================================================
-- APARTADO B - FASE 5: carga acotada de datos (equivale a ~25 días de actividad
-- con la hipótesis de 2.000 billetes/día, 100 viajes/día y 20 reclamaciones/día)
-- Ejecutar con ALUMNO (bdii), como script entero, DESPUÉS de capturar el "antes".
-- Filas previstas: Pasajero 5.000 | Billete 50.000 (40.000 clásicos + 10.000 especiales)
--                  Viaje 2.500 | Pasajero_Viaje 50.000 | Reclamacion 500
-- ==============================================================================

-- 1. Pasajeros (5.000)
INSERT INTO Pasajero (dni, nombre, correo, edad)
SELECT 'P' || LPAD(level, 8, '0'),
       'Pasajero ' || level,
       'p' || level || '@renfe.test',
       18 + MOD(level, 60)
FROM dual CONNECT BY level <= 5000;

-- 2. Billetes (50.000): 1 de cada 5 es especial; taquilla EST-01/1 (dato maestro existente)
INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento, cod_estacion_taq, num_taquilla, dni_pasajero)
SELECT 'B' || LPAD(level, 9, '0'),
       CASE WHEN MOD(level, 5) = 0 THEN 'Especial' ELSE 'Clasico' END,
       DATE '2026-10-08' + TRUNC((level - 1) / 2000),
       20 + MOD(level, 80),
       TO_CHAR(MOD(level, 300) + 1) || CHR(65 + MOD(level, 4)),
       'EST-01', 1,
       'P' || LPAD(MOD(level - 1, 5000) + 1, 8, '0')
FROM dual CONNECT BY level <= 50000;

-- 3. Subtipos de billete (el tipo_billete toma su valor por defecto en cada tabla)
INSERT INTO Billete_Clasico (localizador)
SELECT localizador FROM Billete WHERE tipo_billete = 'Clasico';

INSERT INTO Billete_Especial (localizador, porcentaje_dto, motivo_dto)
SELECT localizador, 10 + MOD(TO_NUMBER(SUBSTR(localizador, 2)), 40), 'Familia numerosa'
FROM Billete WHERE tipo_billete = 'Especial';

-- 4. Viajes (2.500): tren TRN-100, ruta RUT-01 y maquinista del dato maestro
INSERT INTO Viaje (num_serie_tren, cod_ruta, fecha_salida, fecha_llegada, dni_maquinista)
SELECT 'TRN-100', 'RUT-01',
       DATE '2026-11-01' + NUMTODSINTERVAL(level - 1, 'HOUR'),
       DATE '2026-11-01' + NUMTODSINTERVAL(level - 1, 'HOUR') + NUMTODSINTERVAL(6, 'HOUR'),
       '87654321B'
FROM dual CONNECT BY level <= 2500;

-- 5. Pasajeros por viaje (50.000): 20 pasajeros distintos en cada viaje
INSERT INTO Pasajero_Viaje (dni_pasajero, num_serie_tren, cod_ruta, fecha_salida)
SELECT 'P' || LPAD(MOD(level - 1, 5000) + 1, 8, '0'),
       'TRN-100', 'RUT-01',
       DATE '2026-11-01' + NUMTODSINTERVAL(TRUNC((level - 1) / 20), 'HOUR')
FROM dual CONNECT BY level <= 50000;

-- 6. Reclamaciones (500)
INSERT INTO Reclamacion (id_reclamacion, motivo, dni_pasajero)
SELECT 'R' || LPAD(level, 9, '0'),
       'Retraso en el servicio',
       'P' || LPAD(MOD(level - 1, 5000) + 1, 8, '0')
FROM dual CONNECT BY level <= 500;

COMMIT;

-- 7. Comprobación rápida de filas cargadas
SELECT 'PASAJERO' AS tabla, COUNT(*) AS filas FROM Pasajero
UNION ALL SELECT 'BILLETE', COUNT(*) FROM Billete
UNION ALL SELECT 'BILLETE_CLASICO', COUNT(*) FROM Billete_Clasico
UNION ALL SELECT 'BILLETE_ESPECIAL', COUNT(*) FROM Billete_Especial
UNION ALL SELECT 'VIAJE', COUNT(*) FROM Viaje
UNION ALL SELECT 'PASAJERO_VIAJE', COUNT(*) FROM Pasajero_Viaje
UNION ALL SELECT 'RECLAMACION', COUNT(*) FROM Reclamacion;
