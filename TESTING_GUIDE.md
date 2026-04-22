# Guía de Pruebas - Oracle Database Deployment

## 🚀 Inicio Rápido (5 minutos)

### Requisitos
- Docker y Docker Compose instalados
- Python 3.8+
- Git

### Opción 1: Script Automatizado (Recomendado)

```bash
chmod +x test_complete.sh
./test_complete.sh
```

Este script:
- ✅ Verifica todos los requisitos
- ✅ Valida estructura del proyecto
- ✅ Ejecuta escaneo de seguridad
- ✅ Levanta Oracle XE localmente
- ✅ Ejecuta dry-run
- ✅ Ejecuta despliegue
- ✅ Verifica cambios

---

## 📋 Pruebas Manuales Paso a Paso

### PASO 1: Validar Estructura

```bash
ls -la oracle-db-deploy/
```

Debe mostrar:
```
-rw-r--r--  docker-compose.yml
-rw-r--r--  .sqlfluff
drwxr-xr-x  docker/
drwxr-xr-x  liquibase/
drwxr-xr-x  scripts/
drwxr-xr-x  ci-cd/
-rw-r--r--  README.md
```

---

### PASO 2: Verificar Archivos Críticos

```bash
# Ver configuración de Liquibase
cat liquibase/liquibase.properties

# Ver changelog
cat liquibase/changelog/master.xml | head -50

# Ver configuración de SQLFluff
cat .sqlfluff | head -20
```

---

### PASO 3: Ejecutar Escaneo de Seguridad

#### Con Python:

```bash
python3 scripts/security_scan.py liquibase/changelog/
```

**Resultado esperado:**
```
🔍 Escaneando archivos SQL en: liquibase/changelog
✅ No se encontraron violaciones de seguridad
```

#### Con Bash (alternativa):

```bash
bash scripts/security_scan.sh liquibase/changelog/
```

---

### PASO 4: Validar SQL con SQLFluff

```bash
# Instalar SQLFluff (si no está instalado)
pip install sqlfluff sqlfluff[oracle]

# Ejecutar linter
sqlfluff lint liquibase/changelog/ --dialect oracle --config .sqlfluff

# Ver versión de SQLFluff
sqlfluff version
```

**Resultado esperado:**
```
[sql]  L001 Unnecessary whitespace
[sql]  L003 Expected 1 space before comma
```

---

### PASO 5: Levantar Oracle XE Localmente

```bash
cd oracle-db-deploy

# Iniciar contenedores en background
docker-compose up -d

# Verificar que están corriendo
docker-compose ps
```

**Resultado esperado:**
```
CONTAINER ID   IMAGE                      STATUS      PORTS
xxx            gvenzl/oracle-xe:21.3.0    Up 10s      0.0.0.0:1521->1521/tcp
xxx            liquibase/liquibase:4.26.0 Up 10s
```

**⏳ IMPORTANTE:** Esperar 2-3 minutos para que Oracle XE inicie completamente.

Verificar que está listo:
```bash
docker-compose logs oracle-xe | tail -20
```

Buscar mensaje: `DATABASE IS READY TO USE!`

---

### PASO 6: Validar Conexión a Oracle

```bash
# Probar conexión SQL*Plus
docker-compose exec oracle-xe-test sqlplus -v

# Conectar a Oracle y ejecutar query de prueba
docker-compose exec oracle-xe-test sqlplus admin/Oracle123!@XE <<EOF
SELECT 'Oracle está conectado' AS mensaje FROM dual;
EXIT;
EOF
```

**Resultado esperado:**
```
Oracle está conectado
```

---

### PASO 7: Ejecutar Dry-Run (Simulación)

```bash
# Ver SQL que se ejecutaría sin hacer cambios
docker-compose run --rm liquibase liquibase \
  --changeLogFile=changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
  --username=admin \
  --password=Oracle123! \
  update-sql
```

**Resultado esperado:**
```
-- LIQUIBASE UPDATE-SQL OUTPUT
CREATE TABLE ADMIN.USERS (
    USER_ID NUMBER(10) PRIMARY KEY NOT NULL,
    USERNAME VARCHAR2(50) NOT NULL UNIQUE,
    EMAIL VARCHAR2(100) NOT NULL UNIQUE,
    CREATED_AT TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE SEQUENCE ADMIN.USER_SEQ START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER ADMIN.USER_ID_TRIGGER
BEFORE INSERT ON ADMIN.USERS FOR EACH ROW
BEGIN
  IF :NEW.USER_ID IS NULL THEN
    SELECT USER_SEQ.NEXTVAL INTO :NEW.USER_ID FROM DUAL;
  END IF;
END;
/
...
```

---

### PASO 8: Ejecutar Despliegue Real

```bash
# Aplicar cambios a la base de datos
docker-compose run --rm liquibase liquibase \
  --changeLogFile=changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
  --username=admin \
  --password=Oracle123! \
  update
```

**Resultado esperado:**
```
Update successful. 5 changesets have been applied.
```

---

### PASO 9: Verificar Cambios Aplicados

```bash
# Ver tablas creadas
docker-compose exec oracle-xe-test sqlplus -S admin/Oracle123!@XE <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT table_name FROM user_tables WHERE table_name IN ('USERS', 'AUDIT_LOG');
EXIT;
EOF
```

**Resultado esperado:**
```
AUDIT_LOG
USERS
```

---

### PASO 10: Ver Historial de Liquibase

```bash
docker-compose exec oracle-xe-test sqlplus -S admin/Oracle123!@XE <<EOF
SET PAGESIZE 100 HEADING ON FEEDBACK ON
SELECT ID, AUTHOR, FILENAME, EXECTYPE FROM DATABASECHANGELOG ORDER BY ORDEREXECUTED;
EXIT;
EOF
```

**Resultado esperado:**
```
ID                  AUTHOR  FILENAME           EXECTYPE
001_create_users... devops  changelog/master.  EXECUTED
002_create_users... devops  changelog/master.  EXECUTED
003_create_user...  devops  changelog/master.  EXECUTED
004_create_audit... devops  changelog/master.  EXECUTED
005_add_users_ind... devops  changelog/master.  EXECUTED
```

---

## 🧪 Pruebas Avanzadas

### Probar Rollback

```bash
# Revertir último changeset
docker-compose run --rm liquibase liquibase \
  --changeLogFile=changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
  --username=admin \
  --password=Oracle123! \
  rollback-count 1

# Verificar que se revertió
docker-compose exec oracle-xe-test sqlplus -S admin/Oracle123!@XE <<EOF
SELECT table_name FROM user_tables WHERE table_name = 'AUDIT_LOG';
EXIT;
EOF
```

### Ver Logs de Contenedores

```bash
# Logs de Oracle
docker-compose logs oracle-xe

# Logs de Liquibase
docker-compose logs liquibase

# Logs en tiempo real
docker-compose logs -f
```

### Ejecutar Query Personalizada

```bash
docker-compose exec oracle-xe-test sqlplus admin/Oracle123!@XE <<EOF
DESC USERS;
SELECT * FROM user_constraints WHERE table_name = 'USERS';
EXIT;
EOF
```

---

## 🔄 Probar Pipeline CI/CD

### GitHub Actions

1. Hacer push a rama `develop`:
```bash
git add .
git commit -m "Deploy database with Liquibase"
git push origin develop
```

2. Ver ejecución en: `GitHub → Actions → Oracle DB Deployment Pipeline`

3. Verificar stages:
   - ✅ Validate SQL
   - ✅ Test Dry Run
   - ⏸️ Deploy (manual)

### GitLab CI

1. Hacer push a rama `develop`:
```bash
git push gitlab develop
```

2. Ver ejecución en: `GitLab → CI/CD → Pipelines`

3. Verificar stages:
   - ✅ validate:lint
   - ✅ validate:security
   - ✅ test:dry-run:staging
   - ⏸️ deploy:staging (manual)

---

## 🧹 Limpieza

```bash
# Detener contenedores (mantener datos)
docker-compose down

# Detener y eliminar datos
docker-compose down -v

# Eliminar imágenes descargadas
docker rmi gvenzl/oracle-xe:21.3.0 liquibase/liquibase:4.26.0

# Limpiar todo
docker system prune -a
```

---

## ❌ Troubleshooting

### Oracle no levanta

```bash
# Ver logs detallados
docker-compose logs oracle-xe

# Aumentar timeout de espera
sleep 180

# Reiniciar contenedor
docker-compose restart oracle-xe-test
```

### Error de conexión a Liquibase

```bash
# Verificar que Oracle está listo
docker-compose exec oracle-xe-test sqlplus -version

# Verificar red de Docker
docker network ls
docker network inspect oracle-db-deploy_oracle-network
```

### Cambios no se aplicaron

```bash
# Ver status de Liquibase
docker-compose run --rm liquibase liquibase \
  --changeLogFile=changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
  --username=admin \
  --password=Oracle123! \
  status

# Ver historial
docker-compose run --rm liquibase liquibase \
  --changeLogFile=changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
  --username=admin \
  --password=Oracle123! \
  history
```

### SQLFluff no funciona

```bash
# Instalar correctamente
pip install --upgrade sqlfluff sqlfluff[oracle]

# Verificar instalación
sqlfluff version

# Usar alternativa Bash
bash scripts/security_scan.sh liquibase/changelog/
```

---

## 📊 Resultados Esperados

✅ **Exitoso si ves:**
- Contenedores corriendo
- Dry-run sin errores
- 5 changesets aplicados
- Tablas USERS y AUDIT_LOG creadas
- Secuencia USER_SEQ creada
- Trigger USER_ID_TRIGGER funcionando
- Índice en USERS.EMAIL

❌ **Fallo si ves:**
- Error en escaneo de seguridad
- Error de conexión a Oracle
- Errores de SQL en dry-run
- Violaciones de política de seguridad

---

## 🎯 Próximos Pasos

1. ✅ Pruebas locales completadas
2. ⬜ Configurar CI/CD pipeline
3. ⬜ Conectar repositorio (GitHub/GitLab)
4. ⬜ Crear secrets para producción
5. ⬜ Ejecutar primer despliegue a staging
6. ⬜ Ejecutar primer despliegue a producción

---

**¿Necesitas ayuda?** Revisa README.md para más detalles.
