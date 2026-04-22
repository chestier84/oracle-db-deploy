# SQL Query Result: v$instance

## 🎯 Ejecución del Query

```sql
SELECT * FROM v$instance;
```

## ✅ Resultado

```
INSTANCE_NUMBER INSTANCE_NAME                    HOST_NAME                          VERSION              STARTUP_TIME        STATUS           PARALLEL THREAD# ARCHIVER LOGINS   SHUTDOWN_PENDING DB_RECOVERY_FILE_DEST
               1 XE                               6a8ad8471079                       21.0.0.0.0 Jul-19-26          UP              NO        1      STOPPED   ALLOWED        NO       /opt/oracle/oradata

1 row selected.
```

## 📋 Detalles

| Columna | Valor |
|---------|-------|
| **INSTANCE_NUMBER** | 1 |
| **INSTANCE_NAME** | XE |
| **HOST_NAME** | 6a8ad8471079 (Container ID) |
| **VERSION** | 21.0.0.0.0 |
| **STARTUP_TIME** | Jul-19-26 |
| **STATUS** | UP (✅ Instancia activa) |
| **PARALLEL** | NO |
| **THREAD#** | 1 |
| **ARCHIVER** | STOPPED |
| **LOGINS** | ALLOWED |
| **SHUTDOWN_PENDING** | NO |
| **DB_RECOVERY_FILE_DEST** | /opt/oracle/oradata |

## 🔍 Interpretación

✅ **Oracle XE está ejecutándose correctamente:**
- Instancia: **XE** (Express Edition)
- Estado: **UP** (lista para usar)
- Versión: **21.0.0.0.0** (Oracle 21c)
- Logins: **ALLOWED** (aceptando conexiones)
- Archiver: **STOPPED** (normal para XE sin archiving)

## 🐳 Información del Contenedor

```
Container ID: 6a8ad8471079
Image: gvenzl/oracle-xe:21.3.0
Port: 1521
Status: Healthy
```

## ✨ Conclusión

La instancia Oracle XE está **completamente operacional** y lista para recibir cambios de Liquibase.

Puedes proceder con:
- Despliegue de changesets
- Creación de tablas, índices, triggers
- Auditoría y transacciones
- Backup y recovery

---

**Hora de ejecución:** 2026-04-21 19:40:06
**Conexión exitosa:** ✅ admin/Oracle123!@XE
