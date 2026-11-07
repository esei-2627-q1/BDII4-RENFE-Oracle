# BDII_4 · RENFE — Práctica de administración de Oracle 26ai

Práctica de **Bases de Datos II** (Escuela de Ingeniería Informática, Universidade de Vigo):
organización y administración de una base de datos Oracle AI Database 26ai Free a partir del
esquema RENFE del equipo.

**Equipo BDII_4:** Alejandro Francisco Pérez Rodríguez, Mario Pérez González,
Jacobo Montero Naranjo y Pablo Regueira Castaño.

## Contenido

| Carpeta | Qué hay |
| --- | --- |
| `memoria/` | Memoria final en PDF (la que se entrega en Moovi) y en Word, e instrucciones de revisión y reproducción |
| `scripts/` | Todos los scripts SQL, numerados en el orden en que se ejecutan |
| `docker/` | `docker-compose-bdii.yml` del laboratorio (Oracle 26ai Free + VS Code con SQL Developer) |

## Apartados de la memoria

| Apartado | Contenido |
| --- | --- |
| A | Sistemas y necesidades de uso: 5 sistemas, 12 sesiones en punta (15 con margen), RPO 15 min / RTO 60 min |
| B | Tablespaces `ts_renfe_datos`, `ts_renfe_indices` y `ts_renfe_hist`; carga de 50.000 billetes y comparación de extensiones |
| C | Particionado mensual de `Pasajero_Viaje` por `fecha_salida`, con prueba de distribución y de acceso |
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

## Pendiente

La práctica usa el esquema de la **entrega original del Entregable 1** (26 tablas). La repesca del
E1 cambia el modelo (por ejemplo, elimina `Pasajero_Viaje`, que se particiona en el apartado C):
falta confirmar con el profesor con qué esquema debe ir esta práctica.
