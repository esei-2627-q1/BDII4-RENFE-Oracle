-- ==============================================================================
-- APARTADO B - FASE 3: esquema RENFE en ts_renfe_datos / ts_renfe_indices
-- Ejecutar con la cuenta ALUMNO (servicio bdii), como script, tras el 01
-- (que deja ts_renfe_datos como tablespace por defecto de ALUMNO).
-- Derivado de E1_REP_BDII4_RENFE_SQL.sql (repesca de la P1): mismas 28 tablas,
-- restricciones y 3 vistas, sin el borrado previo ni la batería de pruebas.
-- Único cambio en el DDL: cada PRIMARY KEY y UNIQUE lleva
-- USING INDEX TABLESPACE ts_renfe_indices (37 índices). Las tablas caen en
-- ts_renfe_datos por ser el tablespace por defecto de ALUMNO.
-- Al final: 4 índices secundarios y los datos maestros (sin actividad).
-- ==============================================================================

SET DEFINE OFF

-- =============================================================================
-- 2. TABLAS Y RESTRICCIONES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1 EMPLEADO y su especializacion PARCIAL y DISJUNTA (RN-05)
--     Estrategia: una tabla para la superclase y otra por subclase (opcion a).
--     Disyuncion: atributo discriminante tipo_empleado + UNIQUE (dni, tipo) en
--     la superclase y FK compuesta (dni, tipo) en cada subclase, con el tipo
--     fijado por CHECK. Un empleado solo puede aparecer en la subclase cuyo
--     nombre figura en su tipo -> como maximo en una.
--     Parcialidad: tipo_empleado admite NULL (empleado sin rol operativo,
--     como los jefes de estacion, RN-06).
-- -----------------------------------------------------------------------------
CREATE TABLE Empleado (
    dni            VARCHAR2(9)    CONSTRAINT pk_empleado PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    nss            VARCHAR2(12)   CONSTRAINT nn_empleado_nss NOT NULL,
    nombre         VARCHAR2(100)  CONSTRAINT nn_empleado_nombre NOT NULL,
    f_nac          DATE,
    tipo_empleado  VARCHAR2(10),
    CONSTRAINT uq_empleado_nss      UNIQUE (nss) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT uq_empleado_dni_tipo UNIQUE (dni, tipo_empleado) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_empleado_dni     CHECK (REGEXP_LIKE(dni, '^[0-9]{8}[A-Z]$')),
    CONSTRAINT chk_empleado_nss     CHECK (REGEXP_LIKE(nss, '^[0-9]{12}$')),
    CONSTRAINT chk_empleado_tipo    CHECK (tipo_empleado IN ('MAQUINISTA','REVISOR','TECNICO','SEGURIDAD'))
);

-- Atributo MULTIVALUADO telefono (1..2 valores por empleado, RN-05).
-- El maximo de 2 se garantiza de forma declarativa: PK (dni, orden) con
-- orden IN (1,2). UNIQUE evita repetir el mismo numero para un empleado.
-- ON DELETE CASCADE: un telefono no existe sin su empleado.
-- El minimo de 1 telefono no es declarativo: se comprueba en la seccion 5.
CREATE TABLE Empleado_Telefono (
    dni_empleado  VARCHAR2(9),
    orden         NUMBER(1),
    telefono      VARCHAR2(15)  CONSTRAINT nn_emptel_telefono NOT NULL,
    CONSTRAINT pk_empleado_telefono PRIMARY KEY (dni_empleado, orden) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT uq_emptel_telefono   UNIQUE (dni_empleado, telefono) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_emptel_orden     CHECK (orden IN (1, 2)),
    CONSTRAINT chk_emptel_formato   CHECK (REGEXP_LIKE(telefono, '^\+?[0-9]{9,14}$')),
    CONSTRAINT fk_emptel_empleado   FOREIGN KEY (dni_empleado)
        REFERENCES Empleado(dni) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 2.2 ESTACION (entidad fuerte, atributo COMPUESTO direccion, RN-01)
--     Relacion 1:1 DIRIGE (RN-06): Empleado (0,1) dirige (1,1) Estacion, con atributo
--     propio f_inicio_jefatura. FK en el lado de participacion total (Estacion)
--     con NOT NULL (total) y UNIQUE (un empleado dirige como maximo una).
--     Sin cascada: no se puede borrar al jefe sin reasignar antes la estacion.
--     Que el jefe no tenga rol operativo (RN-06) no es declarativo: se
--     comprueba con una consulta en la seccion 5.
-- -----------------------------------------------------------------------------
CREATE TABLE Estacion (
    cod_estacion       VARCHAR2(10)   CONSTRAINT pk_estacion PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    nombre             VARCHAR2(100)  CONSTRAINT nn_estacion_nombre NOT NULL,
    calle              VARCHAR2(100),
    numero             VARCHAR2(10),
    ciudad             VARCHAR2(50),
    cp                 VARCHAR2(5),
    num_vias           NUMBER(3),
    telefono           VARCHAR2(15),
    dni_jefe           VARCHAR2(9)    CONSTRAINT nn_estacion_jefe NOT NULL,
    f_inicio_jefatura  DATE           CONSTRAINT nn_estacion_finicio NOT NULL,
    CONSTRAINT uq_estacion_jefe  UNIQUE (dni_jefe) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_estacion_vias CHECK (num_vias > 0),
    CONSTRAINT chk_estacion_cp   CHECK (REGEXP_LIKE(cp, '^[0-9]{5}$')),
    CONSTRAINT fk_estacion_jefe  FOREIGN KEY (dni_jefe) REFERENCES Empleado(dni)
);

-- -----------------------------------------------------------------------------
-- 2.3 SUBCLASES DE EMPLEADO (RN-05)
--     ON DELETE CASCADE en la FK a Empleado: borrar al empleado elimina su rol
--     (regla de borrado de especializaciones).
-- -----------------------------------------------------------------------------
CREATE TABLE Maquinista (
    dni               VARCHAR2(9)   CONSTRAINT pk_maquinista PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_empleado     VARCHAR2(10)  DEFAULT 'MAQUINISTA' CONSTRAINT nn_maquinista_tipo NOT NULL,
    horas_conduccion  NUMBER(6)     DEFAULT 0,
    CONSTRAINT chk_maquinista_tipo  CHECK (tipo_empleado = 'MAQUINISTA'),
    CONSTRAINT chk_maquinista_horas CHECK (horas_conduccion >= 0),
    CONSTRAINT fk_maquinista_empleado FOREIGN KEY (dni, tipo_empleado)
        REFERENCES Empleado(dni, tipo_empleado) ON DELETE CASCADE
);

CREATE TABLE Revisor (
    dni            VARCHAR2(9)   CONSTRAINT pk_revisor PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_empleado  VARCHAR2(10)  DEFAULT 'REVISOR' CONSTRAINT nn_revisor_tipo NOT NULL,
    CONSTRAINT chk_revisor_tipo CHECK (tipo_empleado = 'REVISOR'),
    CONSTRAINT fk_revisor_empleado FOREIGN KEY (dni, tipo_empleado)
        REFERENCES Empleado(dni, tipo_empleado) ON DELETE CASCADE
);

-- Atributo MULTIVALUADO idiomas del revisor (RN-05) -> tabla propia (algoritmo, paso 6).
CREATE TABLE Revisor_Idioma (
    dni_revisor  VARCHAR2(9),
    idioma       VARCHAR2(30),
    CONSTRAINT pk_revisor_idioma PRIMARY KEY (dni_revisor, idioma) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT fk_revidioma_revisor FOREIGN KEY (dni_revisor)
        REFERENCES Revisor(dni) ON DELETE CASCADE
);

-- Relacion REFLEXIVA SUPERVISA (RN-08), 1:N:
--   rol supervisor (0,N) / rol supervisado (0,1).
-- FK reflexiva en el lado N (supervisado). ON DELETE SET NULL: si el
-- supervisor deja la empresa, sus supervisados quedan pendientes de
-- reasignacion; no se borran en cadena.
CREATE TABLE Tecnico (
    dni             VARCHAR2(9)   CONSTRAINT pk_tecnico PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_empleado   VARCHAR2(10)  DEFAULT 'TECNICO' CONSTRAINT nn_tecnico_tipo NOT NULL,
    especialidad    VARCHAR2(100),
    dni_supervisor  VARCHAR2(9),
    CONSTRAINT chk_tecnico_tipo      CHECK (tipo_empleado = 'TECNICO'),
    CONSTRAINT chk_tecnico_no_autosup CHECK (dni_supervisor <> dni),
    CONSTRAINT fk_tecnico_empleado FOREIGN KEY (dni, tipo_empleado)
        REFERENCES Empleado(dni, tipo_empleado) ON DELETE CASCADE,
    CONSTRAINT fk_tecnico_supervisor FOREIGN KEY (dni_supervisor)
        REFERENCES Tecnico(dni) ON DELETE SET NULL
);

-- Relacion 1:N CONTROLA (RN-07): Seguridad (1,1) - Estacion (1,N).
-- FK NOT NULL en Seguridad. Sin cascada hacia Estacion: no se puede cerrar una
-- estacion con personal de seguridad asignado sin reasignarlo antes.
CREATE TABLE Seguridad (
    dni            VARCHAR2(9)   CONSTRAINT pk_seguridad PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_empleado  VARCHAR2(10)  DEFAULT 'SEGURIDAD' CONSTRAINT nn_seguridad_tipo NOT NULL,
    nivel          NUMBER(1),
    cod_estacion   VARCHAR2(10)  CONSTRAINT nn_seguridad_estacion NOT NULL,
    CONSTRAINT chk_seguridad_tipo  CHECK (tipo_empleado = 'SEGURIDAD'),
    CONSTRAINT chk_seguridad_nivel CHECK (nivel BETWEEN 1 AND 5),
    CONSTRAINT fk_seguridad_empleado FOREIGN KEY (dni, tipo_empleado)
        REFERENCES Empleado(dni, tipo_empleado) ON DELETE CASCADE,
    CONSTRAINT fk_seguridad_estacion FOREIGN KEY (cod_estacion)
        REFERENCES Estacion(cod_estacion)
);

-- -----------------------------------------------------------------------------
-- 2.4 ENTIDADES DEBILES DE ESTACION: ANDEN (RN-02) y TAQUILLA (RN-03)
--     Relaciones identificadoras TIENE_ANDEN y TIENE_TAQUILLA.
--     PK = clave del propietario + clave parcial. ON DELETE CASCADE: no existen
--     andenes ni taquillas fuera de su estacion (participacion total).
-- -----------------------------------------------------------------------------
CREATE TABLE Anden (
    cod_estacion  VARCHAR2(10),
    num_anden     NUMBER(3),
    longitud      NUMBER(5,1),          -- metros
    CONSTRAINT pk_anden          PRIMARY KEY (cod_estacion, num_anden) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_anden_num     CHECK (num_anden > 0),
    CONSTRAINT chk_anden_long    CHECK (longitud > 0),
    CONSTRAINT fk_anden_estacion FOREIGN KEY (cod_estacion)
        REFERENCES Estacion(cod_estacion) ON DELETE CASCADE
);

CREATE TABLE Taquilla (
    cod_estacion  VARCHAR2(10),
    num_taquilla  NUMBER(3),
    estado        VARCHAR2(15)  DEFAULT 'Cerrada' CONSTRAINT nn_taquilla_estado NOT NULL,
    turno         CHAR(1),              -- M = manana, T = tarde, N = noche
    CONSTRAINT pk_taquilla          PRIMARY KEY (cod_estacion, num_taquilla) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_taquilla_num     CHECK (num_taquilla > 0),
    CONSTRAINT chk_taquilla_estado  CHECK (estado IN ('Abierta','Cerrada','Mantenimiento')),
    CONSTRAINT chk_taquilla_turno   CHECK (turno IN ('M','T','N')),
    CONSTRAINT fk_taquilla_estacion FOREIGN KEY (cod_estacion)
        REFERENCES Estacion(cod_estacion) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 2.5 OTRAS ENTIDADES FUERTES
-- -----------------------------------------------------------------------------
-- Almacen (RN-04): atributo COMPUESTO direccion.
CREATE TABLE Almacen (
    cod_alm     VARCHAR2(10)  CONSTRAINT pk_almacen PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    telefono    VARCHAR2(15),
    max_trenes  NUMBER(4),
    calle       VARCHAR2(100),
    numero      VARCHAR2(10),
    ciudad      VARCHAR2(50),
    cp          VARCHAR2(5),
    CONSTRAINT chk_almacen_max CHECK (max_trenes > 0),
    CONSTRAINT chk_almacen_cp  CHECK (REGEXP_LIKE(cp, '^[0-9]{5}$'))
);

-- Pasajero (RN-19). edad es un atributo DERIVADO de f_nac: no se almacena; se calcula en
-- Vista_Pasajero_Edad (una columna virtual no admite SYSDATE).
CREATE TABLE Pasajero (
    dni     VARCHAR2(9)    CONSTRAINT pk_pasajero PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    nombre  VARCHAR2(100)  CONSTRAINT nn_pasajero_nombre NOT NULL,
    correo  VARCHAR2(100),
    f_nac   DATE,
    CONSTRAINT uq_pasajero_correo  UNIQUE (correo) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_pasajero_dni    CHECK (REGEXP_LIKE(dni, '^[0-9]{8}[A-Z]$')),
    CONSTRAINT chk_pasajero_correo CHECK (INSTR(correo, '@') > 1),
    CONSTRAINT chk_pasajero_fnac   CHECK (f_nac >= DATE '1900-01-01')
);

-- Ruta (RN-14). Relaciones 1:N ORIGEN y DESTINO con Estacion:
--   Ruta (1,1) - Estacion (0,N) en cada una -> FK NOT NULL en Ruta.
--   * CHECK: el origen y el destino son estaciones distintas.
--   * UNIQUE (cod_ruta, cod_estacion_destino): superclave que permite a Viaje
--     referenciar el destino de su ruta y exigir asi, de forma declarativa,
--     que el anden de llegada este en la estacion destino (RN-18).
--   Sin cascada: no se cierra una estacion que es origen o destino de rutas.
CREATE TABLE Ruta (
    cod_ruta              VARCHAR2(10)  CONSTRAINT pk_ruta PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    cod_estacion_origen   VARCHAR2(10)  CONSTRAINT nn_ruta_origen NOT NULL,
    cod_estacion_destino  VARCHAR2(10)  CONSTRAINT nn_ruta_destino NOT NULL,
    distancia             NUMBER(7,2),          -- km
    CONSTRAINT uq_ruta_destino    UNIQUE (cod_ruta, cod_estacion_destino) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_ruta_distancia CHECK (distancia > 0),
    CONSTRAINT chk_ruta_extremos  CHECK (cod_estacion_origen <> cod_estacion_destino),
    CONSTRAINT fk_ruta_origen     FOREIGN KEY (cod_estacion_origen)  REFERENCES Estacion(cod_estacion),
    CONSTRAINT fk_ruta_destino    FOREIGN KEY (cod_estacion_destino) REFERENCES Estacion(cod_estacion)
);

-- Proveedor (RN-24): atributo COMPUESTO direccion.
CREATE TABLE Proveedor (
    cif     VARCHAR2(9)    CONSTRAINT pk_proveedor PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    nombre  VARCHAR2(100)  CONSTRAINT nn_proveedor_nombre NOT NULL,
    email   VARCHAR2(100),
    calle   VARCHAR2(100),
    numero  VARCHAR2(10),
    ciudad  VARCHAR2(50),
    cp      VARCHAR2(5),
    CONSTRAINT chk_proveedor_cif   CHECK (REGEXP_LIKE(cif, '^[A-Z][0-9]{7}[0-9A-Z]$')),
    CONSTRAINT chk_proveedor_email CHECK (INSTR(email, '@') > 1),
    CONSTRAINT chk_proveedor_cp    CHECK (REGEXP_LIKE(cp, '^[0-9]{5}$'))
);

-- Pieza (RN-25). Relacion 1:N SUMINISTRA (RN-24): FK NOT NULL en Pieza (lado 1,1).
-- Sin cascada: no se borra un proveedor con piezas en inventario.
CREATE TABLE Pieza (
    cod_pieza      VARCHAR2(10)   CONSTRAINT pk_pieza PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    nombre         VARCHAR2(100)  CONSTRAINT nn_pieza_nombre NOT NULL,
    descripcion    VARCHAR2(255),
    precio         NUMBER(8,2),
    cif_proveedor  VARCHAR2(9)    CONSTRAINT nn_pieza_proveedor NOT NULL,
    CONSTRAINT chk_pieza_precio    CHECK (precio >= 0),
    CONSTRAINT fk_pieza_proveedor  FOREIGN KEY (cif_proveedor) REFERENCES Proveedor(cif)
);

-- Entidad DEBIL Bulto (RN-22): propietario Pasajero, relacion identificadora
-- LLEVA, clave parcial
-- num_bulto, ON DELETE CASCADE por dependencia de existencia.
CREATE TABLE Bulto (
    dni_pasajero  VARCHAR2(9),
    num_bulto     NUMBER(3),
    peso_kg       NUMBER(5,2),
    ancho_cm      NUMBER(5,1),
    largo_cm      NUMBER(5,1),
    CONSTRAINT pk_bulto          PRIMARY KEY (dni_pasajero, num_bulto) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_bulto_num     CHECK (num_bulto > 0),
    CONSTRAINT chk_bulto_peso    CHECK (peso_kg > 0),
    CONSTRAINT chk_bulto_medidas CHECK (ancho_cm > 0 AND largo_cm > 0),
    CONSTRAINT fk_bulto_pasajero FOREIGN KEY (dni_pasajero)
        REFERENCES Pasajero(dni) ON DELETE CASCADE
);

-- Reclamacion. Relacion 1:N GENERA (RN-23). Sin cascada: una reclamacion es un registro con
-- valor legal y debe conservarse; impide borrar pasajeros con reclamaciones.
CREATE TABLE Reclamacion (
    id_reclamacion  VARCHAR2(10)   CONSTRAINT pk_reclamacion PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    fecha           DATE           DEFAULT SYSDATE CONSTRAINT nn_reclamacion_fecha NOT NULL,
    motivo          VARCHAR2(500)  CONSTRAINT nn_reclamacion_motivo NOT NULL,
    dni_pasajero    VARCHAR2(9)    CONSTRAINT nn_reclamacion_pasajero NOT NULL,
    CONSTRAINT fk_reclamacion_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni)
);

-- -----------------------------------------------------------------------------
-- 2.6 TREN: generalizacion TOTAL y SOLAPADA (RN-09, RN-10) + SUBCLASE COMPARTIDA (RN-11)
--     Tabla para la superclase y una por subclase (opcion a, unica valida para
--     solapamiento sin redundancia). Un tren mixto aparece en Tren_Pasajeros y
--     en Tren_Mercancia a la vez.
--     Tren_Mixto es subclase compartida: subconjunto de la INTERSECCION de
--     ambas subclases -> dos FK, una a cada superclase. Atributo propio:
--     carga_max_con_pasaje (toneladas autorizadas cuando circula con viajeros).
--     La participacion TOTAL no es expresable con DDL declarativo: se verifica
--     con la consulta de la seccion 5, igual que la regla "todo tren de ambos
--     tipos es mixto" (RN-11).
-- -----------------------------------------------------------------------------
-- Relacion 1:N GUARDA (RN-04, RN-09): Almacen (0,N) - Tren (1,1). FK NOT NULL.
-- Sin cascada: un tren no desaparece al cerrar un almacen; debe reubicarse.
CREATE TABLE Tren (
    num_serie        VARCHAR2(15)  CONSTRAINT pk_tren PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    modelo           VARCHAR2(50),
    potencia_kw      NUMBER(6),
    fecha_fabr       DATE,
    num_max_vagones  NUMBER(3),
    cod_alm          VARCHAR2(10)  CONSTRAINT nn_tren_almacen NOT NULL,
    CONSTRAINT chk_tren_potencia CHECK (potencia_kw > 0),
    CONSTRAINT chk_tren_maxvag   CHECK (num_max_vagones > 0),
    CONSTRAINT fk_tren_almacen   FOREIGN KEY (cod_alm) REFERENCES Almacen(cod_alm)
);

CREATE TABLE Tren_Pasajeros (
    num_serie  VARCHAR2(15)  CONSTRAINT pk_tren_pasajeros PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    clase      VARCHAR2(20),
    CONSTRAINT chk_trenpas_clase CHECK (clase IN ('Cercanias','Media Distancia','Larga Distancia','Alta Velocidad')),
    CONSTRAINT fk_trenpas_tren FOREIGN KEY (num_serie)
        REFERENCES Tren(num_serie) ON DELETE CASCADE
);

CREATE TABLE Tren_Mercancia (
    num_serie       VARCHAR2(15)  CONSTRAINT pk_tren_mercancia PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_mercancia  VARCHAR2(100),
    CONSTRAINT fk_trenmer_tren FOREIGN KEY (num_serie)
        REFERENCES Tren(num_serie) ON DELETE CASCADE
);

CREATE TABLE Tren_Mixto (
    num_serie             VARCHAR2(15)  CONSTRAINT pk_tren_mixto PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    carga_max_con_pasaje  NUMBER(6,2)   CONSTRAINT nn_trenmix_carga NOT NULL,
    CONSTRAINT chk_trenmix_carga CHECK (carga_max_con_pasaje > 0),
    CONSTRAINT fk_trenmix_pasajeros FOREIGN KEY (num_serie)
        REFERENCES Tren_Pasajeros(num_serie) ON DELETE CASCADE,
    CONSTRAINT fk_trenmix_mercancia FOREIGN KEY (num_serie)
        REFERENCES Tren_Mercancia(num_serie) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 2.7 VAGON: entidad DEBIL de Tren (RN-12), identificadora COMPONE + REFLEXIVA 1:1
--     ACOPLA (RN-13): rol precede (0,1) / rol sigue (0,1).
--     * FK reflexiva (num_serie_tren, vagon_sig_num) dentro del MISMO tren.
--     * UNIQUE (num_serie_tren, vagon_sig_num) garantiza el maximo 1 del rol
--       "sigue" (dos vagones no pueden tener el mismo siguiente). Como Oracle
--       indexa las claves parcialmente nulas, ademas solo puede haber un vagon
--       con siguiente NULL por tren: un unico ultimo vagon.
--     * Capacidad: plazas para Pasajeros/Restaurante, toneladas para
--       Mercancias; un CHECK de fila exige la coherencia tipo-unidad.
--     ON DELETE CASCADE hacia Tren (dependencia de existencia); la reflexiva
--     no lleva accion: hay que desacoplar antes de retirar un vagon intermedio.
-- -----------------------------------------------------------------------------
CREATE TABLE Vagon (
    num_serie_tren  VARCHAR2(15),
    num_vagon       NUMBER(3),
    tipo_vagon      VARCHAR2(12)  CONSTRAINT nn_vagon_tipo NOT NULL,
    plazas          NUMBER(4),
    toneladas       NUMBER(6,2),
    anho_fab        NUMBER(4),
    vagon_sig_num   NUMBER(3),
    CONSTRAINT pk_vagon           PRIMARY KEY (num_serie_tren, num_vagon) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT uq_vagon_siguiente UNIQUE (num_serie_tren, vagon_sig_num) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_vagon_num      CHECK (num_vagon > 0),
    CONSTRAINT chk_vagon_tipo     CHECK (tipo_vagon IN ('Pasajeros','Restaurante','Mercancias')),
    CONSTRAINT chk_vagon_capacidad CHECK (
        (tipo_vagon IN ('Pasajeros','Restaurante') AND plazas > 0 AND toneladas IS NULL)
     OR (tipo_vagon = 'Mercancias' AND toneladas > 0 AND plazas IS NULL)),
    CONSTRAINT chk_vagon_anho     CHECK (anho_fab BETWEEN 1900 AND 2100),
    CONSTRAINT chk_vagon_sig      CHECK (vagon_sig_num <> num_vagon),
    CONSTRAINT fk_vagon_tren      FOREIGN KEY (num_serie_tren)
        REFERENCES Tren(num_serie) ON DELETE CASCADE,
    CONSTRAINT fk_vagon_siguiente FOREIGN KEY (num_serie_tren, vagon_sig_num)
        REFERENCES Vagon(num_serie_tren, num_vagon)
);

-- -----------------------------------------------------------------------------
-- 2.8 RELACION TERNARIA INSTALA (RN-26): Tecnico - Pieza - Tren, con el
--     atributo MULTIVALUADO fecha_instalacion (una terna puede repetirse en
--     fechas distintas).
--     Transformacion: la ternaria daria INSTALA(tecnico, pieza, tren) y su
--     multivaluado una tabla (tecnico, pieza, tren, fecha). Como la relacion no
--     tiene mas atributos y toda instalacion tiene al menos una fecha, la
--     primera seria una proyeccion redundante de la segunda: se implanta solo
--     esta, con PK = las tres claves + fecha.
--     Sin cascadas: es historico de mantenimiento.
-- -----------------------------------------------------------------------------
CREATE TABLE Instalacion (
    dni_tecnico        VARCHAR2(9),
    cod_pieza          VARCHAR2(10),
    num_serie_tren     VARCHAR2(15),
    fecha_instalacion  DATE,
    CONSTRAINT pk_instalacion  PRIMARY KEY (dni_tecnico, cod_pieza, num_serie_tren, fecha_instalacion) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT fk_inst_tecnico FOREIGN KEY (dni_tecnico)    REFERENCES Tecnico(dni),
    CONSTRAINT fk_inst_pieza   FOREIGN KEY (cod_pieza)      REFERENCES Pieza(cod_pieza),
    CONSTRAINT fk_inst_tren    FOREIGN KEY (num_serie_tren) REFERENCES Tren(num_serie)
);

-- -----------------------------------------------------------------------------
-- 2.9 AGREGACION VIAJE (RN-15): relacion N:M CUBRE entre Tren y Ruta
--     tratada como entidad de nivel superior.
--     * PK (tren, ruta, fecha_salida): un tren puede cubrir la misma ruta
--       muchas veces en fechas distintas.
--     * duracion_h: atributo DERIVADO, columna virtual (horas).
--     * OPERA (RN-16), 1:N: FK NOT NULL a Maquinista (viaje 1,1).
--     * LLEGA (RN-18), 1:N: FK NOT NULL a Anden (viaje 1,1). Una segunda FK
--       (cod_ruta, cod_estacion_llegada) -> Ruta(cod_ruta, cod_estacion_destino)
--       obliga a que el anden de llegada este en la estacion destino de la ruta.
--     Sin cascadas: un viaje es un registro historico.
-- -----------------------------------------------------------------------------
CREATE TABLE Viaje (
    num_serie_tren         VARCHAR2(15),
    cod_ruta               VARCHAR2(10),
    fecha_salida           DATE,
    fecha_llegada          DATE          CONSTRAINT nn_viaje_llegada NOT NULL,
    duracion_h             NUMBER GENERATED ALWAYS AS
                               (ROUND((fecha_llegada - fecha_salida) * 24, 2)) VIRTUAL,
    dni_maquinista         VARCHAR2(9)   CONSTRAINT nn_viaje_maquinista NOT NULL,
    cod_estacion_llegada   VARCHAR2(10)  CONSTRAINT nn_viaje_est_llegada NOT NULL,
    num_anden_llegada      NUMBER(3)     CONSTRAINT nn_viaje_and_llegada NOT NULL,
    CONSTRAINT pk_viaje            PRIMARY KEY (num_serie_tren, cod_ruta, fecha_salida) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_viaje_fechas    CHECK (fecha_llegada > fecha_salida),
    CONSTRAINT fk_viaje_tren       FOREIGN KEY (num_serie_tren) REFERENCES Tren(num_serie),
    CONSTRAINT fk_viaje_ruta       FOREIGN KEY (cod_ruta)       REFERENCES Ruta(cod_ruta),
    CONSTRAINT fk_viaje_maquinista FOREIGN KEY (dni_maquinista) REFERENCES Maquinista(dni),
    CONSTRAINT fk_viaje_anden      FOREIGN KEY (cod_estacion_llegada, num_anden_llegada)
        REFERENCES Anden(cod_estacion, num_anden),
    CONSTRAINT fk_viaje_destino    FOREIGN KEY (cod_ruta, cod_estacion_llegada)
        REFERENCES Ruta(cod_ruta, cod_estacion_destino)
);

-- Relacion N:M REVISA (RN-17) entre Revisor (0,N) y Viaje (0,N), atributo propio
-- incidencias. ON DELETE CASCADE desde Viaje (si un viaje programado se anula,
-- sus asignaciones pierden sentido). Sin cascada desde Revisor: el historico
-- de inspecciones se conserva.
CREATE TABLE Revisor_Viaje (
    dni_revisor     VARCHAR2(9),
    num_serie_tren  VARCHAR2(15),
    cod_ruta        VARCHAR2(10),
    fecha_salida    DATE,
    incidencias     NUMBER(3)  DEFAULT 0 CONSTRAINT nn_revviaje_inc NOT NULL,
    CONSTRAINT pk_revisor_viaje  PRIMARY KEY (dni_revisor, num_serie_tren, cod_ruta, fecha_salida) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_revviaje_inc  CHECK (incidencias >= 0),
    CONSTRAINT fk_revviaje_revisor FOREIGN KEY (dni_revisor) REFERENCES Revisor(dni),
    CONSTRAINT fk_revviaje_viaje   FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida)
        REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 2.10 BILLETE (RN-20): especializacion TOTAL y DISJUNTA (RN-21)
--      * Disyuncion: discriminante tipo_billete + UNIQUE (localizador, tipo) y
--        FK compuesta en cada subclase con el tipo fijado por CHECK.
--      * Totalidad: tipo_billete NOT NULL; la existencia de la fila en la
--        subclase se verifica en la seccion 5 (no expresable con DDL).
--      * VENDE, COMPRA y CORRESPONDE (RN-20): 1:N con FK NOT NULL.
--        El billete se vincula al viaje concreto; un pasajero "realiza" un
--        viaje si tiene billete para el (se elimina la antigua relacion
--        Pasajero-Viaje, que duplicaba esta informacion).
--      * UNIQUE (viaje, asiento): un asiento no se vende dos veces en un viaje.
--      Sin cascadas: el billete es un registro de venta.
-- -----------------------------------------------------------------------------
CREATE TABLE Billete (
    localizador       VARCHAR2(10)  CONSTRAINT pk_billete PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_billete      VARCHAR2(8)   CONSTRAINT nn_billete_tipo NOT NULL,
    f_compra          DATE          DEFAULT SYSDATE CONSTRAINT nn_billete_fcompra NOT NULL,
    precio            NUMBER(6,2)   CONSTRAINT nn_billete_precio NOT NULL,
    asiento           VARCHAR2(5)   CONSTRAINT nn_billete_asiento NOT NULL,
    cod_estacion_taq  VARCHAR2(10)  CONSTRAINT nn_billete_estacion NOT NULL,
    num_taquilla      NUMBER(3)     CONSTRAINT nn_billete_taquilla NOT NULL,
    dni_pasajero      VARCHAR2(9)   CONSTRAINT nn_billete_pasajero NOT NULL,
    num_serie_tren    VARCHAR2(15)  CONSTRAINT nn_billete_tren NOT NULL,
    cod_ruta          VARCHAR2(10)  CONSTRAINT nn_billete_ruta NOT NULL,
    fecha_salida      DATE          CONSTRAINT nn_billete_salida NOT NULL,
    CONSTRAINT uq_billete_loc_tipo UNIQUE (localizador, tipo_billete) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT uq_billete_asiento  UNIQUE (num_serie_tren, cod_ruta, fecha_salida, asiento) USING INDEX TABLESPACE ts_renfe_indices,
    CONSTRAINT chk_billete_tipo    CHECK (tipo_billete IN ('Clasico','Especial')),
    CONSTRAINT chk_billete_precio  CHECK (precio >= 0),
    CONSTRAINT fk_billete_taquilla FOREIGN KEY (cod_estacion_taq, num_taquilla)
        REFERENCES Taquilla(cod_estacion, num_taquilla),
    CONSTRAINT fk_billete_pasajero FOREIGN KEY (dni_pasajero) REFERENCES Pasajero(dni),
    CONSTRAINT fk_billete_viaje    FOREIGN KEY (num_serie_tren, cod_ruta, fecha_salida)
        REFERENCES Viaje(num_serie_tren, cod_ruta, fecha_salida)
);

-- Subclase Billete_Clasico (RN-21): tarifa comercial propia.
CREATE TABLE Billete_Clasico (
    localizador   VARCHAR2(10)  CONSTRAINT pk_billete_clasico PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_billete  VARCHAR2(8)   DEFAULT 'Clasico' CONSTRAINT nn_billcla_tipo NOT NULL,
    tarifa        VARCHAR2(8)   CONSTRAINT nn_billcla_tarifa NOT NULL,
    CONSTRAINT chk_billcla_tipo   CHECK (tipo_billete = 'Clasico'),
    CONSTRAINT chk_billcla_tarifa CHECK (tarifa IN ('Basico','Elige','Premium')),
    CONSTRAINT fk_billcla_billete FOREIGN KEY (localizador, tipo_billete)
        REFERENCES Billete(localizador, tipo_billete) ON DELETE CASCADE
);

-- Subclase Billete_Especial (RN-21): porcentaje y motivo del descuento.
CREATE TABLE Billete_Especial (
    localizador     VARCHAR2(10)   CONSTRAINT pk_billete_especial PRIMARY KEY USING INDEX TABLESPACE ts_renfe_indices,
    tipo_billete    VARCHAR2(8)    DEFAULT 'Especial' CONSTRAINT nn_billesp_tipo NOT NULL,
    porcentaje_dto  NUMBER(5,2)    CONSTRAINT nn_billesp_dto NOT NULL,
    motivo_dto      VARCHAR2(255)  CONSTRAINT nn_billesp_motivo NOT NULL,
    CONSTRAINT chk_billesp_tipo   CHECK (tipo_billete = 'Especial'),
    CONSTRAINT chk_billesp_dto    CHECK (porcentaje_dto > 0 AND porcentaje_dto <= 100),
    CONSTRAINT fk_billesp_billete FOREIGN KEY (localizador, tipo_billete)
        REFERENCES Billete(localizador, tipo_billete) ON DELETE CASCADE
);

-- =============================================================================
-- 3. VISTAS
-- =============================================================================

-- Vista NO ACTUALIZABLE: resumen de infraestructura por estacion.
-- Finalidad: consultar de un vistazo cuantos andenes y taquillas tiene cada
-- estacion sin repetir los JOIN ni la agregacion.
-- No actualizable: combina tres tablas y usa GROUP BY y COUNT; cada fila de la
-- vista agrupa varias filas base, por lo que Oracle no puede trasladar un DML
-- a filas concretas (ORA-01732).
CREATE OR REPLACE VIEW Vista_Resumen_Estacion
    (cod_estacion, nombre, ciudad, num_andenes, num_taquillas) AS
SELECT e.cod_estacion, e.nombre, e.ciudad,
       COUNT(DISTINCT a.num_anden), COUNT(DISTINCT t.num_taquilla)
FROM   Estacion e
       LEFT JOIN Anden    a ON a.cod_estacion = e.cod_estacion
       LEFT JOIN Taquilla t ON t.cod_estacion = e.cod_estacion
GROUP  BY e.cod_estacion, e.nombre, e.ciudad;

-- Vista ACTUALIZABLE: agenda de contacto de proveedores para logistica.
-- Actualizable: proyeccion de una unica tabla, sin JOIN, DISTINCT, GROUP BY,
-- funciones de agregacion ni expresiones; incluye la PK, por lo que cada fila
-- de la vista corresponde a una fila de Proveedor.
CREATE OR REPLACE VIEW Vista_Proveedor
    (cif, nombre, email, ciudad, cp) AS
SELECT cif, nombre, email, ciudad, cp
FROM   Proveedor;

-- Vista de apoyo al atributo DERIVADO edad (no es una de las dos obligatorias).
CREATE OR REPLACE VIEW Vista_Pasajero_Edad
    (dni, nombre, f_nac, edad) AS
SELECT dni, nombre, f_nac, TRUNC(MONTHS_BETWEEN(SYSDATE, f_nac) / 12)
FROM   Pasajero;


-- =============================================================================
-- 4. ÍNDICES SECUNDARIOS (en ts_renfe_indices)
--    La FK de Billete a Viaje ya queda cubierta por uq_billete_asiento, que
--    empieza por (num_serie_tren, cod_ruta, fecha_salida).
-- =============================================================================
CREATE INDEX ix_billete_fcompra  ON Billete (f_compra)                       TABLESPACE ts_renfe_indices;
CREATE INDEX ix_billete_pasajero ON Billete (dni_pasajero)                   TABLESPACE ts_renfe_indices;
CREATE INDEX ix_billete_taquilla ON Billete (cod_estacion_taq, num_taquilla) TABLESPACE ts_renfe_indices;
CREATE INDEX ix_viaje_fecha      ON Viaje (fecha_salida)                     TABLESPACE ts_renfe_indices;

-- =============================================================================
-- 5. DATOS MAESTROS (estado "antes" de la carga del apartado B)
--    Los datos de prueba de la sección 4 de la repesca, salvo los registros de
--    actividad (Pasajero, Viaje, Revisor_Viaje, Billete y subtipos, Bulto,
--    Reclamacion e Instalacion), que se dejan vacíos para la carga del script 03.
-- =============================================================================
INSERT INTO Empleado VALUES ('11111111A', '280000000001', 'Ana Lopez',    DATE '1975-03-12', NULL);
INSERT INTO Empleado VALUES ('22222222B', '360000000002', 'Bruno Varela', DATE '1979-07-01', NULL);
INSERT INTO Empleado VALUES ('12121212L', '280000000012', 'Rosa Diaz',    DATE '1983-04-18', NULL);
INSERT INTO Empleado VALUES ('13131313M', '360000000013', 'Tomas Rey',    DATE '1987-10-03', NULL);
INSERT INTO Empleado VALUES ('33333333C', '280000000003', 'Carlos Ruiz',  DATE '1982-01-20', 'MAQUINISTA');
INSERT INTO Empleado VALUES ('44444444D', '360000000004', 'Lucia Otero',  DATE '1990-05-05', 'REVISOR');
INSERT INTO Empleado VALUES ('55555555E', '280000000005', 'Marta Gil',    DATE '1970-11-30', 'TECNICO');
INSERT INTO Empleado VALUES ('66666666F', '280000000006', 'Ivan Soto',    DATE '1995-02-14', 'TECNICO');
INSERT INTO Empleado VALUES ('77777777G', '280000000007', 'Pedro Sanz',   DATE '1988-09-09', 'SEGURIDAD');
INSERT INTO Empleado VALUES ('88888888H', '360000000008', 'Sara Pazos',   DATE '1992-12-24', 'SEGURIDAD');
INSERT INTO Empleado_Telefono VALUES ('11111111A', 1, '600111222');
INSERT INTO Empleado_Telefono VALUES ('11111111A', 2, '912000111');
INSERT INTO Empleado_Telefono VALUES ('22222222B', 1, '600222333');
INSERT INTO Empleado_Telefono VALUES ('12121212L', 1, '600121212');
INSERT INTO Empleado_Telefono VALUES ('13131313M', 1, '600131313');
INSERT INTO Empleado_Telefono VALUES ('33333333C', 1, '600333444');
INSERT INTO Empleado_Telefono VALUES ('44444444D', 1, '600444555');
INSERT INTO Empleado_Telefono VALUES ('44444444D', 2, '986444555');
INSERT INTO Empleado_Telefono VALUES ('55555555E', 1, '600555666');
INSERT INTO Empleado_Telefono VALUES ('66666666F', 1, '600666777');
INSERT INTO Empleado_Telefono VALUES ('77777777G', 1, '600777888');
INSERT INTO Empleado_Telefono VALUES ('88888888H', 1, '600888999');
INSERT INTO Estacion VALUES ('MAD-ATO', 'Madrid Puerta de Atocha', 'Plaza del Emperador Carlos V', 's/n',
                             'Madrid', '28045', 15, '912320320', '11111111A', DATE '2020-01-15');
INSERT INTO Estacion VALUES ('VGO-URZ', 'Vigo Urzaiz', 'Rua de Urzaiz', '71',
                             'Vigo', '36201', 8, '986000000', '22222222B', DATE '2021-06-01');
INSERT INTO Maquinista (dni, horas_conduccion) VALUES ('33333333C', 1200);
INSERT INTO Revisor    (dni)                   VALUES ('44444444D');
INSERT INTO Revisor_Idioma VALUES ('44444444D', 'Espanol');
INSERT INTO Revisor_Idioma VALUES ('44444444D', 'Gallego');
INSERT INTO Revisor_Idioma VALUES ('44444444D', 'Ingles');
INSERT INTO Tecnico (dni, especialidad, dni_supervisor) VALUES ('55555555E', 'Traccion electrica', NULL);
INSERT INTO Tecnico (dni, especialidad, dni_supervisor) VALUES ('66666666F', 'Frenos', '55555555E');
INSERT INTO Seguridad (dni, nivel, cod_estacion) VALUES ('77777777G', 3, 'MAD-ATO');
INSERT INTO Seguridad (dni, nivel, cod_estacion) VALUES ('88888888H', 2, 'VGO-URZ');
INSERT INTO Anden VALUES ('MAD-ATO', 1, 400);
INSERT INTO Anden VALUES ('MAD-ATO', 2, 400);
INSERT INTO Anden VALUES ('VGO-URZ', 1, 350);
INSERT INTO Taquilla VALUES ('MAD-ATO', 1, 'Abierta', 'M');
INSERT INTO Taquilla VALUES ('VGO-URZ', 1, 'Abierta', 'T');
INSERT INTO Almacen VALUES ('ALM-MAD', '913000000', 20, 'Calle Mendez Alvaro', '1', 'Madrid', '28045');
INSERT INTO Almacen VALUES ('ALM-VGO', '986111111', 6,  'Rua de Areal', '10', 'Vigo', '36201');
INSERT INTO Ruta VALUES ('R-MAD-VGO', 'MAD-ATO', 'VGO-URZ', 600);
INSERT INTO Proveedor VALUES ('A12345674', 'Ferropiezas SA', 'ventas@ferropiezas.es', 'Calle Hierro', '3', 'Bilbao', '48001');
INSERT INTO Proveedor VALUES ('B87654321', 'Galifrenos SL',  'info@galifrenos.es',    'Rua Nova',     '8', 'Ourense','32001');
INSERT INTO Pieza VALUES ('P-001', 'Pastilla de freno', 'Pastilla sinterizada para disco', 120.50, 'B87654321');
INSERT INTO Pieza VALUES ('P-002', 'Pantografo',        'Captador de corriente 25 kV',    8900.00, 'A12345674');
INSERT INTO Tren VALUES ('TRN-100', 'S-112', 8800, DATE '2012-05-01', 12, 'ALM-MAD');
INSERT INTO Tren VALUES ('TRN-200', 'S-253', 5600, DATE '2009-03-01', 30, 'ALM-MAD');
INSERT INTO Tren VALUES ('TRN-300', 'S-599', 2400, DATE '2010-10-01', 6,  'ALM-VGO');
INSERT INTO Tren_Pasajeros VALUES ('TRN-100', 'Alta Velocidad');
INSERT INTO Tren_Mercancia VALUES ('TRN-200', 'Contenedores');
INSERT INTO Tren_Pasajeros VALUES ('TRN-300', 'Media Distancia');
INSERT INTO Tren_Mercancia VALUES ('TRN-300', 'Paqueteria');
INSERT INTO Tren_Mixto     VALUES ('TRN-300', 40);
INSERT INTO Vagon VALUES ('TRN-100', 2, 'Pasajeros',   80,  NULL, 2012, NULL);
INSERT INTO Vagon VALUES ('TRN-100', 1, 'Restaurante', 30,  NULL, 2012, 2);
INSERT INTO Vagon VALUES ('TRN-200', 1, 'Mercancias',  NULL, 60,  2009, NULL);
INSERT INTO Vagon VALUES ('TRN-300', 2, 'Mercancias',  NULL, 40,  2010, NULL);
INSERT INTO Vagon VALUES ('TRN-300', 1, 'Pasajeros',   60,  NULL, 2010, 2);

COMMIT;
