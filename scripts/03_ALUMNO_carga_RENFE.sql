-- ==============================================================================
-- APARTADO B - FASE 5: carga acotada de datos (equivale a ~25 días de actividad
-- con la hipótesis de 2.000 billetes/día, 100 viajes/día y 20 reclamaciones/día)
-- Ejecutar con ALUMNO (bdii), como script entero, DESPUÉS de capturar el "antes".
-- Filas previstas: Pasajero 5.000 | Viaje 2.500 | Billete 50.000
--                  (40.000 clásicos + 10.000 especiales) | Reclamacion 500
-- Esquema de la repesca: cada billete va ligado a un viaje (20 asientos distintos
-- por viaje), los DNI cumplen chk_pasajero_dni y la edad se deriva de f_nac.
-- ==============================================================================

-- 1. Pasajeros (5.000): DNI de 8 cifras + letra de control
INSERT INTO Pasajero (dni, nombre, correo, f_nac)
SELECT LPAD(level, 8, '0') || SUBSTR('TRWAGMYFPDXBNJZSQVHLCKE', MOD(level, 23) + 1, 1),
       'Pasajero ' || level,
       'p' || level || '@renfe.test',
       DATE '1950-01-01' + MOD(level * 37, 20000)
FROM dual CONNECT BY level <= 5000;

-- 2. Viajes (2.500): uno por hora desde el 01-11-2026, tren TRN-100 en la ruta
--    R-MAD-VGO, maquinista y andén de llegada de los datos maestros
INSERT INTO Viaje (num_serie_tren, cod_ruta, fecha_salida, fecha_llegada,
                   dni_maquinista, cod_estacion_llegada, num_anden_llegada)
SELECT 'TRN-100', 'R-MAD-VGO',
       DATE '2026-11-01' + NUMTODSINTERVAL(level - 1, 'HOUR'),
       DATE '2026-11-01' + NUMTODSINTERVAL(level - 1, 'HOUR') + NUMTODSINTERVAL(330, 'MINUTE'),
       '33333333C', 'VGO-URZ', 1
FROM dual CONNECT BY level <= 2500;

-- 3. Billetes (50.000): 20 por viaje (asientos 1A..5D), 1 de cada 5 especial,
--    comprados entre el 08-10 y el 01-11-2026 en la taquilla MAD-ATO/1
INSERT INTO Billete (localizador, tipo_billete, f_compra, precio, asiento,
                     cod_estacion_taq, num_taquilla, dni_pasajero,
                     num_serie_tren, cod_ruta, fecha_salida)
SELECT 'B' || LPAD(level, 9, '0'),
       CASE WHEN MOD(level, 5) = 0 THEN 'Especial' ELSE 'Clasico' END,
       DATE '2026-10-08' + TRUNC((level - 1) / 2000),
       20 + MOD(level, 80),
       TO_CHAR(TRUNC(MOD(level - 1, 20) / 4) + 1) || CHR(65 + MOD(level - 1, 4)),
       'MAD-ATO', 1,
       LPAD(MOD(level - 1, 5000) + 1, 8, '0')
         || SUBSTR('TRWAGMYFPDXBNJZSQVHLCKE', MOD(MOD(level - 1, 5000) + 1, 23) + 1, 1),
       'TRN-100', 'R-MAD-VGO',
       DATE '2026-11-01' + NUMTODSINTERVAL(TRUNC((level - 1) / 20), 'HOUR')
FROM dual CONNECT BY level <= 50000;

-- 4. Subtipos de billete (tipo_billete toma su valor por defecto en cada tabla)
INSERT INTO Billete_Clasico (localizador, tarifa)
SELECT localizador,
       CASE MOD(TO_NUMBER(SUBSTR(localizador, 2)), 3)
            WHEN 0 THEN 'Basico' WHEN 1 THEN 'Elige' ELSE 'Premium' END
FROM Billete WHERE tipo_billete = 'Clasico';

INSERT INTO Billete_Especial (localizador, porcentaje_dto, motivo_dto)
SELECT localizador, 10 + MOD(TO_NUMBER(SUBSTR(localizador, 2)), 40), 'Familia numerosa'
FROM Billete WHERE tipo_billete = 'Especial';

-- 5. Reclamaciones (500)
INSERT INTO Reclamacion (id_reclamacion, motivo, dni_pasajero)
SELECT 'R' || LPAD(level, 9, '0'),
       'Retraso en el servicio',
       LPAD(MOD(level - 1, 5000) + 1, 8, '0')
         || SUBSTR('TRWAGMYFPDXBNJZSQVHLCKE', MOD(MOD(level - 1, 5000) + 1, 23) + 1, 1)
FROM dual CONNECT BY level <= 500;

COMMIT;

-- 6. Comprobación rápida de filas cargadas
SELECT 'PASAJERO' AS tabla, COUNT(*) AS filas FROM Pasajero
UNION ALL SELECT 'VIAJE', COUNT(*) FROM Viaje
UNION ALL SELECT 'BILLETE', COUNT(*) FROM Billete
UNION ALL SELECT 'BILLETE_CLASICO', COUNT(*) FROM Billete_Clasico
UNION ALL SELECT 'BILLETE_ESPECIAL', COUNT(*) FROM Billete_Especial
UNION ALL SELECT 'RECLAMACION', COUNT(*) FROM Reclamacion;
