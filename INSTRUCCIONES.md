# Revisión y reproducción de la práctica (esquema de la repesca)

Instrucciones para revisar la memoria y, si se quiere, reproducir la práctica en vuestro Docker.
Los resultados esperados son los del esquema de la **repesca del Entregable 1** (28 tablas) y coinciden
con las evidencias del anexo de la memoria.

## 1. Revisión sin instalar nada

Las hipótesis y decisiones son del equipo, no del enunciado: si cambia una, hay que cambiarla en todos
los apartados donde aparece.

| Decisión | Valor en la memoria | Apartados |
| --- | --- | --- |
| Carga prevista | 2.000 billetes/día, 100 viajes/día, 20 reclamaciones/día, 12 meses | A, B, C, E |
| Sesiones en punta | 2 réplicas × pool de 4 + 2 tareas + 2 de administración = 12 (15 con margen) | A, D, F |
| Recuperación | RPO 15 min, RTO 60 min | A, E |
| Particionado | `Billete` por mes de `fecha_salida` (copia `Billete_Part`): PK global y UNIQUE de asiento local | C |
| Redo | 3 grupos × 2 miembros × 128 MiB y `ARCHIVE_LAG_TARGET = 900` (propuesta, no aplicada) | E |
| Cuentas | `renfe_app`, `renfe_batch`, `renfe_admin` (propuesta, no creadas) | F |

Comprobad apartado por apartado:

- [ ] Portada: los cuatro nombres bien escritos.
- [ ] B: 28 tablas en `TS_RENFE_DATOS` y 41 índices en `TS_RENFE_INDICES` (B-07, B-08); antes 44 segmentos y después 63 (B-09, B-12).
- [ ] C: 14.400 / 14.880 / 14.880 / 5.840 / 0 filas por partición y plan con `Pstart = Pstop = 2` (C-02, C-04).
- [ ] D: SGA y PGA (D-01 a D-03).
- [ ] E: redo de 5.022.692 bytes sin índices y 49.836.928 con índices (E-11) y avisos del alert log (E-12).
- [ ] F: `ORA-02391` y `ORA-01536` (F-02 a F-04).

Puntos débiles que pueden preguntar en la defensa:

- El crecimiento a 12 meses es una extrapolación lineal de una sola carga.
- Copias RMAN, FRA y datos comparten el volumen de Docker: protegen de errores, no de perder el disco.
- Cada partición con datos ocupa 8 MiB aunque tenga pocas filas (32 MiB frente a 5 MiB de `Billete`).
- Las evidencias de ARCHIVELOG, RMAN, procesos y pruebas de F son del 01/11 (antes de la repesca); no dependen del esquema.

## 2. Reproducir en vuestro Docker

Requisitos:

- [ ] `docker compose -f docker/docker-compose-bdii.yml up -d` y el contenedor `oracle-26ai` en `(healthy)`.
- [ ] En SQL Developer para VS Code: `SYSTEM` al servicio `free` y `ALUMNO` al servicio `bdii`.
- [ ] `ALUMNO` sin tablas (`SELECT COUNT(*) FROM user_tables;` = 0). Si tiene las de una versión anterior, ejecutad antes `99_limpieza.sql`.

Reglas: "como script" es el botón de ejecutar script; las consultas sueltas, con Ctrl+Enter (la extensión
solo muestra la tabla de la primera consulta de un script). Mirad siempre qué conexión está activa.
Si algo falla, no borréis nada para arreglarlo: copiad el primer error.

| Paso | Script (cuenta) | Resultado esperado |
| --- | --- | --- |
| 1 | `01_SYSTEM_tablespaces_y_cuotas.sql` (SYSTEM) | 2 tablespaces, cuotas 512/256 MiB y `ts_renfe_datos` por defecto |
| 2 | `02_ALUMNO_esquema_RENFE.sql` (ALUMNO) | 28 tablas, 3 vistas, 4 índices secundarios y datos maestros (sin pasajeros, viajes ni billetes) |
| 3 | Consultas B de `10` | Antes: 44 segmentos de 65.536 bytes y 0 filas en las tablas de actividad |
| 4 | `03_ALUMNO_carga_RENFE.sql` (ALUMNO) | 5.000 pasajeros, 2.500 viajes, 50.000 billetes (40.000 + 10.000), 500 reclamaciones |
| 5 | Consultas B de `10` | Después: 63 segmentos; 76 extensiones y 9,44 MiB en datos; 168 y 18 MiB en índices; `BILLETE` con 16 extensiones de 8 bloques y 4 de 128 |
| 6 | `04_SYSTEM_ampliar_indices.sql` (SYSTEM) | Máximo de 512 MiB en los dos archivos |
| 7 | `05_SYSTEM_tablespace_historico.sql` (SYSTEM) y `06_ALUMNO_particionado.sql` (ALUMNO) | `Billete_Part` con 14.400 / 14.880 / 14.880 / 5.840 / 0 filas; plan `PARTITION RANGE SINGLE`, `Pstart = Pstop = 2` |
| 8 | `07_ALUMNO_traslado_particion.sql` (ALUMNO) | `P_2026_11` e `IP_2026_11` en `TS_RENFE_HIST`; `PK_BILLETE_PART` VALID; cuota de histórico ≈ 9.109.504 bytes |
| 9 | `08_medida_redo_manual.sql`, sentencia a sentencia | ≈ 100 B de redo por fila sin índices y ≈ 997 con los 6 índices |
| 10 | `09_SYSTEM_prueba_sesiones_y_cuota.sql` (SYSTEM y `usr_prueba`) | La 3.ª conexión falla con `ORA-02391`; el `INSERT` con `ORA-01536`. Desconectad las conexiones `usr_prueba` antes de la limpieza (o saldrá `ORA-01940`) |

Los `block_id`, PID y bytes exactos de redo cambian de una instalación a otra.

## 3. ARCHIVELOG y RMAN (opcional y delicado)

No está en los scripts a propósito: reinicia la base, corta las conexiones y queda activo. Si lo hacéis,
seguid las páginas 5 a 7 de la guía de la unidad 2, en la terminal del contenedor
(`docker exec -it oracle-26ai bash` y `sqlplus / as sysdba`), una sentencia cada vez. La copia en frío
solo vale entre `SHUTDOWN IMMEDIATE` y `STARTUP MOUNT`; más fácil, tras el cambio, RMAN fuera de la FRA
(`BACKUP DATABASE FORMAT '/opt/oracle/oradata/rman/db_%U.bkp';` y `RESTORE DATABASE VALIDATE;`).
`ALTER SYSTEM ARCHIVE LOG CURRENT;` una sola vez. Para apagar, `docker compose ... down -t 120`, nunca `down -v`.

## 4. Limpieza

`99_limpieza.sql`: parte 1 con ALUMNO (vistas y tablas, incluida `Billete_Part`) y parte 2 con SYSTEM
(tablespace por defecto de vuelta a `ALUMNO_DATA` y borrado de los tres tablespaces). Borra datos.
No deshace ARCHIVELOG ni borra copias RMAN.
