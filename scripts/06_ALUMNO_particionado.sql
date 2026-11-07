-- ==============================================================================
-- APARTADO C - FASE 2: particionado de Pasajero_Viaje (RANGE por fecha_salida)
-- Ejecutar con ALUMNO (bdii), como script entero, DESPUÉS de crear ts_renfe_hist con SYSTEM.
-- Se crea Pasajero_Viaje_Part con el mismo contenido y se conserva la original para comparar.
-- Mismo patrón que la guía de la unidad 1 (SQL_REGISTROS_PART): particiones con
-- nombre y tablespace explícitos, índices LOCAL, y traslado posterior de la histórica.
-- ==============================================================================

-- 1. Tabla particionada: una partición por mes, más una de cierre (MAXVALUE)
CREATE TABLE Pasajero_Viaje_Part (
    dni_pasajero   VARCHAR2(9)  NOT NULL,
    num_serie_tren VARCHAR2(15) NOT NULL,
    cod_ruta       VARCHAR2(10) NOT NULL,
    fecha_salida   DATE         NOT NULL,
    CONSTRAINT fk_pasviajep_pasajero FOREIGN KEY (dni_pasajero)
        REFERENCES Pasajero(dni) ON DELETE CASCADE,
    CONSTRAINT fk_pasviajep_viaje FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida)
        REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida) ON DELETE CASCADE
) PARTITION BY RANGE (fecha_salida) (
    PARTITION p_2026_11 VALUES LESS THAN (DATE '2026-12-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2026_12 VALUES LESS THAN (DATE '2027-01-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2027_01 VALUES LESS THAN (DATE '2027-02-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2027_02 VALUES LESS THAN (DATE '2027-03-01') TABLESPACE ts_renfe_datos,
    PARTITION p_futuro  VALUES LESS THAN (MAXVALUE)          TABLESPACE ts_renfe_datos
);

-- 2. Clave primaria con índice LOCAL (fecha_salida forma parte de la clave)
CREATE UNIQUE INDEX pk_pasviaje_part
    ON Pasajero_Viaje_Part (dni_pasajero, num_serie_tren, cod_ruta, fecha_salida)
    LOCAL (
        PARTITION ip_2026_11 TABLESPACE ts_renfe_indices,
        PARTITION ip_2026_12 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_01 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_02 TABLESPACE ts_renfe_indices,
        PARTITION ip_futuro  TABLESPACE ts_renfe_indices
    );

ALTER TABLE Pasajero_Viaje_Part ADD CONSTRAINT pk_pasviaje_part
    PRIMARY KEY (dni_pasajero, num_serie_tren, cod_ruta, fecha_salida)
    USING INDEX pk_pasviaje_part;

-- 3. Índice secundario por viaje, también LOCAL
CREATE INDEX ix_pasviajep_viaje
    ON Pasajero_Viaje_Part (num_serie_tren, cod_ruta, fecha_salida)
    LOCAL (
        PARTITION ip_2026_11 TABLESPACE ts_renfe_indices,
        PARTITION ip_2026_12 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_01 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_02 TABLESPACE ts_renfe_indices,
        PARTITION ip_futuro  TABLESPACE ts_renfe_indices
    );

-- 4. Mismo conjunto de datos que la tabla original (50.000 filas)
INSERT INTO Pasajero_Viaje_Part (dni_pasajero, num_serie_tren, cod_ruta, fecha_salida)
SELECT dni_pasajero, num_serie_tren, cod_ruta, fecha_salida FROM Pasajero_Viaje;
COMMIT;
