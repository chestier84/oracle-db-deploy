# Proyecto: Oracle Database Deployment con Liquibase

## 📋 Descripción General

Sistema completo de control de versiones y despliegue de cambios en bases de datos Oracle, incluyendo:

- **Motor de Despliegue**: Liquibase con formato SQL
- **Validación de Sintaxis**: SQLFluff con dialecto Oracle
- **Escaneo de Seguridad**: Script de validación de políticas
- **Dry Run**: Simulación de cambios antes de ejecutar
- **Pipeline CI/CD**: GitHub Actions y GitLab CI
- **Entorno de Pruebas**: Docker Compose con Oracle XE

---

## 📁 Estructura del Proyecto

```
oracle-db-deploy/
├── docker-compose.yml                    # Entorno de pruebas local
├── .sqlfluff                             # Configuración de SQLFluff
│
├── docker/
│   └── init.sql                          # Script de inicialización
│
├── liquibase/
│   ├── liquibase.properties              # Configuración de Liquibase
│   └── changelog/
│       └── master.xml                    # Changelog con etiquetas Oracle
│
├── scripts/
│   ├── security_scan.py                  # Escaneo de seguridad (Python)
│   └── security_scan.sh                  # Escaneo de seguridad (Bash)
│
└── ci-cd/
    ├── github-actions.yml                # Pipeline GitHub Actions
    └── gitlab-ci.yml                     # Pipeline GitLab CI
```

---

## 🚀 Inicio Rápido

### 1. Levantar entorno local con Docker Compose

```bash
docker-compose up -d
```

**Credenciales de prueba:**
- Usuario: `admin`
- Contraseña: `Oracle123!`
- Host: `localhost:1521`
- SID: `XE`

### 2. Validar con SQLFluff

```bash
sqlfluff lint liquibase/changelog/ --dialect oracle --config .sqlfluff
```

### 3. Ejecutar escaneo de seguridad

```bash
# Con Python
python3 scripts/security_scan.py liquibase/changelog/

# O con Bash
bash scripts/security_scan.sh liquibase/changelog/
```

### 4. Ejecutar Dry Run

```bash
liquibase \
  --changeLogFile=liquibase/changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@localhost:1521:XE \
  --username=admin \
  --password=Oracle123! \
  update-sql
```

### 5. Ejecutar despliegue

```bash
liquibase \
  --changeLogFile=liquibase/changelog/master.xml \
  --driver=oracle.jdbc.driver.OracleDriver \
  --url=jdbc:oracle:thin:@localhost:1521:XE \
  --username=admin \
  --password=Oracle123! \
  update
```

---

## 🔐 Validación de Seguridad

El script `security_scan.py` valida que los archivos SQL no contengan:

- ❌ `TRUNCATE` - Eliminación sin logs de auditoría
- ❌ `DROP TABLE/SCHEMA` - Eliminación de esquemas
- ❌ `DELETE FROM` sin cláusula WHERE - Pérdida de datos
- ❌ `ANY PRIVILEGE` - Permisos excesivos
- ❌ `GRANT TO PUBLIC` - Exposición de seguridad
- ❌ `BECOME USER` - Suplantación de usuarios
- ❌ `PASSWORD` en SQL - Contraseñas en código
- ❌ `SYS.` o `SYSTEM.` - Acceso a objetos del sistema
- ❌ `EXECUTE IMMEDIATE` sin validación - Riesgo de inyección SQL

---

## 🔧 Configuración del Pipeline CI/CD

### GitHub Actions

**Archivo:** `.github/workflows/deploy-oracle.yml`

**Etapas:**
1. **validate-sql** - Lint con SQLFluff y escaneo de seguridad
2. **test-dry-run** - Prueba en ambiente de test
3. **deploy-to-production** - Despliegue en producción
4. **rollback** - Rollback en caso de fallo

**Variables secretas requeridas:**
```
ORACLE_HOST
ORACLE_PORT
ORACLE_SID
ORACLE_USER
ORACLE_PASSWORD
ORACLE_WALLET (opcional, en base64)
```

### GitLab CI

**Archivo:** `.gitlab-ci.yml`

**Stages:**
- `validate` - Lint, seguridad, formato
- `test` - Dry-run en staging
- `deploy` - Despliegue manual
- `rollback` - Rollback manual

**Variables por entorno:**
```
ORACLE_PROD_HOST
ORACLE_PROD_PORT
ORACLE_PROD_SID
ORACLE_PROD_USER
ORACLE_PROD_PASSWORD
ORACLE_STAGING_* (análogo)
ORACLE_WALLET_B64 (opcional)
```

---

## 📊 Archivo Changelog.xml

El archivo `liquibase/changelog/master.xml` contiene:

1. **Changeset 001**: Crear tabla `USERS`
2. **Changeset 002**: Crear secuencia `USER_SEQ`
3. **Changeset 003**: Crear trigger para auto-ID
4. **Changeset 004**: Crear tabla de auditoría `AUDIT_LOG`
5. **Changeset 005**: Crear índice en `USERS.EMAIL`

Cada changeset incluye instrucciones de **rollback** automático.

---

## 🛠 Configuración de SQLFluff

El archivo `.sqlfluff` configura:

- **Dialecto**: Oracle
- **Línea máxima**: 120 caracteres
- **Indentación**: 4 espacios
- **Reglas**: 63 reglas de linting habilitadas
- **Estilo**: Keywords en mayúsculas, identificadores en minúsculas

---

## 💾 Liquibase Properties

El archivo `liquibase/liquibase.properties` incluye:

```properties
driver: oracle.jdbc.driver.OracleDriver
url: jdbc:oracle:thin:@oracle-xe:1521:XE
username: admin
password: Oracle123!
changeLogFile: changelog/master.xml
```

---

## 🧪 Probar Localmente

```bash
# 1. Levantar Oracle XE
docker-compose up -d oracle-xe
docker-compose logs -f oracle-xe

# 2. Esperar a que esté listo (aprox 2 minutos)

# 3. Validar SQL
python3 scripts/security_scan.py liquibase/changelog/
sqlfluff lint liquibase/changelog/ --dialect oracle

# 4. Ejecutar dry-run
docker-compose run --rm liquibase liquibase update-sql

# 5. Ejecutar despliegue
docker-compose run --rm liquibase liquibase update

# 6. Verificar cambios
docker-compose exec oracle-xe sqlplus admin/Oracle123!@XE @<<EOF
SELECT table_name FROM user_tables;
SELECT sequence_name FROM user_sequences;
EXIT;
EOF
```

---

## 🔄 Conexión TCPS con Wallet

Para producción con TCPS y Oracle Wallet:

1. Obtener `wallet.zip` de OCI/Oracle Cloud
2. Codificar en base64: `base64 wallet.zip > wallet.b64`
3. Crear secret en GitHub/GitLab: `ORACLE_WALLET_B64`
4. El pipeline decodificará automáticamente

---

## 📝 Buenas Prácticas

✅ **DO:**
- Crear changesets pequeños y aislados
- Incluir rollbacks en cada changeset
- Ejecutar dry-run antes de deploy
- Validar seguridad en pre-commit
- Documentar cambios importantes

❌ **DON'T:**
- Incluir contraseñas en SQL
- Usar `TRUNCATE` o `DROP`
- `DELETE` sin cláusula WHERE
- Cambios directos sin versionado
- Ignorar validaciones de seguridad

---

## 🆘 Troubleshooting

**Oracle no levanta:**
```bash
docker-compose logs oracle-xe
docker-compose down -v  # Limpiar volúmenes
```

**Error de conexión:**
```bash
# Verificar port 1521
nc -zv localhost 1521
```

**Fallo en Liquibase:**
```bash
docker-compose logs liquibase
# Verificar liquibase.properties
```

**SQLFluff no funciona:**
```bash
pip install --upgrade sqlfluff sqlfluff[oracle]
sqlfluff version
```

---

## 📚 Referencias

- [Liquibase Docs](https://docs.liquibase.com/)
- [SQLFluff](https://www.sqlfluff.com/)
- [Oracle JDBC Driver](https://www.oracle.com/database/technologies/appdev/jdbc.html)
- [Oracle XE Docker](https://github.com/gvenzl/oci-oracle-xe)

---

**Autor:** DevOps Team  
**Última actualización:** 2024
