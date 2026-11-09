-- ==============================================================================
-- APARTADO C - FASE 2: particionado de Billete (RANGE mensual por fecha_salida)
-- Ejecutar con ALUMNO (bdii), como script entero, DESPUÉS de crear ts_renfe_hist con SYSTEM.
-- Se crea Billete_Part con el mismo contenido y se conserva la original para comparar.
-- Mismo patrón que la guía de la unidad 1 (SQL_REGISTROS_PART): particiones con
-- nombre y tablespace explícitos, índices LOCAL, y traslado posterior de la histórica.
-- La clave de partición es la fecha del viaje (fecha_salida), no la de compra:
-- las consultas e informes son por viaje y un mes se cierra cuando han salido sus trenes.
-- ==============================================================================

-- 1. Tabla particionada: una partición por mes, más una de cierre (MAXVALUE)
CREATE TABLE Billete_Part (
    localizador       VARCHAR2(10)  NOT NULL,
    tipo_billete      VARCHAR2(8)   NOT NULL,
    f_compra          DATE          NOT NULL,
    precio            NUMBER(6,2)   NOT NULL,
    asiento           VARCHAR2(5)   NOT NULL,
    cod_estacion_taq  VARCHAR2(10)  NOT NULL,
    num_taquilla      NUMBER(3)     NOT NULL,
    dni_pasajero      VARCHAR2(9)   NOT NULL,
    num_serie_tren    VARCHAR2(15)  NOT NULL,
    cod_ruta          VARCHAR2(10)  NOT NULL,
    fecha_salida      DATE          NOT NULL,
    CONSTRAINT chk_billetep_tipo   CHECK (tipo_billete IN ('Clasico','Especial')),
    CONSTRAINT chk_billetep_precio CHECK (precio >= 0),
    CONSTRAINT fk_billetep_taquilla FOREIGN KEY (cod_estacion_taq, num_taquilla)
        REFERENCES Taquilla(cod_estacion, num_taquilla),
    CONSTRAINT fk_billetep_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni),
    CONSTRAINT fk_billetep_viaje    FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida)
        REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida)
) PARTITION BY RANGE (fecha_salida) (
    PARTITION p_2026_11 VALUES LESS THAN (DATE '2026-12-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2026_12 VALUES LESS THAN (DATE '2027-01-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2027_01 VALUES LESS THAN (DATE '2027-02-01') TABLESPACE ts_renfe_datos,
    PARTITION p_2027_02 VALUES LESS THAN (DATE '2027-03-01') TABLESPACE ts_renfe_datos,
    PARTITION p_futuro  VALUES LESS THAN (MAXVALUE)          TABLESPACE ts_renfe_datos
);

-- 2. Clave primaria: índice GLOBAL sin particionar. localizador no contiene la
--    clave de partición, así que su índice único no puede ser LOCAL.
ALTER TABLE Billete_Part ADD CONSTRAINT pk_billete_part PRIMARY KEY (localizador)
    USING INDEX TABLESPACE ts_renfe_indices;

-- 3. Asiento único por viaje: incluye fecha_salida, así que su índice único es LOCAL
CREATE UNIQUE INDEX uq_billetep_asiento
    ON Billete_Part (num_serie_tren, cod_ruta, fecha_salida, asiento)
    LOCAL (
        PARTITION ip_2026_11 TABLESPACE ts_renfe_indices,
        PARTITION ip_2026_12 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_01 TABLESPACE ts_renfe_indices,
        PARTITION ip_2027_02 TABLESPACE ts_renfe_indices,
        PARTITION ip_futuro  TABLESPACE ts_renfe_indices
    );

ALTER TABLE Billete_Part ADD CONSTRAINT uq_billetep_asiento
    UNIQUE (num_serie_tren, cod_ruta, fecha_salida, asiento)
    USING INDEX uq_billetep_asiento;

-- 4. Mismo conjunto de datos que la tabla original (50.000 filas)
INSERT INTO Billete_Part (localizador, tipo_billete, f_compra, precio, asiento,
                          cod_estacion_taq, num_taquilla, dni_pasajero,
                          num_serie_tren, cod_ruta, fecha_salida)
SELECT localizador, tipo_billete, f_compra, precio, asiento,
       cod_estacion_taq, num_taquilla, dni_pasajero,
       num_serie_tren, cod_ruta, fecha_salida
FROM Billete;
COMMIT;
