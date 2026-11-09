# BDII_4 · RENFE — Práctica de administración de Oracle 26ai

Práctica de **Bases de Datos II** (Escuela de Ingeniería Informática, Universidade de Vigo):
organización y administración de una base de datos Oracle AI Database 26ai Free a partir del
esquema RENFE del equipo.

**Equipo BDII_4:** Alejandro Francisco Pérez Rodríguez, Mario Pérez González,
Jacobo Montero Naranjo y Pablo Regueira Castaño.

## Contenido

| Carpeta | Qué hay |
| --- | --- |
| `memoria/` | Memoria final en PDF (la que se entrega en Moovi), su fuente LaTeX en `memoria/latex/` y el ZIP para Overleaf; versión Word e instrucciones de revisión y reproducción |
| `scripts/` | Todos los scripts SQL, numerados en el orden en que se ejecutan |
| `docker/` | `docker-compose-bdii.yml` del laboratorio (Oracle 26ai Free + VS Code con SQL Developer) |

## Apartados de la memoria

| Apartado | Contenido |
| --- | --- |
| A | Sistemas y necesidades de uso: 5 sistemas, 12 sesiones en punta (15 con margen), RPO 15 min / RTO 60 min |
| B | Tablespaces `ts_renfe_datos`, `ts_renfe_indices` y `ts_renfe_hist`; carga de 50.000 billetes y comparación de extensiones |
| C | Particionado mensual de `Billete` por `fecha_salida` (PK global + UNIQUE de asiento local), con prueba de distribución y de acceso |
| D | SGA y PGA: gestión automática de SGA (1536M) y PGA objetivo de 512M |
| E | Redo y archivado: ARCHIVELOG activado, FRA de 4 GiB, medida del redo y propuesta de 3 grupos × 2 miembros × 128 MiB |
| F | Cuentas, perfiles y cuotas, con pruebas de `ORA-02391` (sesiones) y `ORA-01536` (cuota) |

## Reproducir la práctica

1. Arrancar el laboratorio: `docker compose -f docker/docker-compose-bdii.yml up -d` y esperar a `(healthy)`.
2. En SQL Developer para VS Code, conexiones `SYSTEM` (servicio `free`) y `ALUMNO` (servicio `bdii`).
3. Ejecutar los scripts de `scripts/` en orden (01 → 09); el nombre indica la cuenta.
   `10_consultas_de_comprobacion.sql` sirve para comparar resultados y `99_limpieza.sql` lo deshace todo.

Los detalles, los resultados esperados y los pasos delicados (ARCHIVELOG y RMAN) están en
`memoria/Instrucciones_revision_y_reproduccion.pdf`.

> **Aviso:** para apagar, `docker compose -f docker/docker-compose-bdii.yml down -t 120`.
> Nunca `down -v`: borra el volumen y la base entera.

## Esquema

La práctica usa el esquema de la **repesca del Entregable 1** (28 tablas,
[bdii4-renfe-p1-repesca](https://github.com/DYeicob/bdii4-renfe-p1-repesca)): el DDL de
`02_ALUMNO_esquema_RENFE.sql` es el de la repesca sin cambios, salvo `USING INDEX TABLESPACE`.
Como la repesca elimina `Pasajero_Viaje`, el apartado C particiona `Billete`.

## Memoria (LaTeX)

La memoria sigue la plantilla de entrega de Moovi (apartados A–F con las mismas tablas y campos) y
se escribe en `memoria/latex/main.tex`. Las evidencias B-07 a B-15, B-18, B-19, C-01 a C-08 y E-11
son salidas de SQL*Plus guardadas en `memoria/latex/evidencias/` y se incluyen tal cual; el resto son
capturas en `memoria/latex/figuras/`.

- **Overleaf:** New Project → Upload Project → `memoria/Memoria_RENFE_Oracle_BDII_4_overleaf.zip`
  (compilador pdfLaTeX). Copiad el PDF resultante a `memoria/Memoria_RENFE_Oracle_BDII_4.pdf`.
- **En local:** `pdflatex main.tex` dos veces dentro de `memoria/latex/` (TeX Live con los paquetes
  `xcharter`, `bera`, `newunicodechar`, `needspace`, `titlesec` y `tcolorbox`).

Si se cambia un `.tex`, regenerad también el ZIP de Overleaf para que no quede desfasado.

## Pendiente

- Confirmar con el profesor que la práctica va con el esquema de la repesca.
- `memoria/Instrucciones_revision_y_reproduccion.pdf` conserva los resultados esperados del esquema
  antiguo (26 tablas, 34 índices, 72/731 B de redo…); la memoria ya tiene los nuevos.
