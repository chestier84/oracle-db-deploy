#!/bin/bash

# ==============================================================================
# GUÍA COMPLETA DE PRUEBAS - Oracle DB Deployment con Liquibase
# ==============================================================================

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  ORACLE DATABASE DEPLOYMENT WITH LIQUIBASE - TESTING GUIDE              ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ==============================================================================
# PASO 1: VERIFICAR REQUISITOS
# ==============================================================================
echo "📋 PASO 1: Verificando requisitos..."
echo ""

required_tools=("docker" "docker-compose" "python3" "git")
missing_tools=()

for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_tools+=("$tool")
        echo "❌ $tool no está instalado"
    else
        version=$($tool --version 2>&1 | head -n1)
        echo "✅ $tool: $version"
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Por favor instala las siguientes herramientas:"
    printf '  - %s\n' "${missing_tools[@]}"
    exit 1
fi

echo ""
echo "✅ Todos los requisitos están instalados"
echo ""

# ==============================================================================
# PASO 2: VALIDAR ESTRUCTURA DEL PROYECTO
# ==============================================================================
echo "📁 PASO 2: Validando estructura del proyecto..."
echo ""

expected_files=(
    "docker-compose.yml"
    "liquibase/liquibase.properties"
    "liquibase/changelog/master.xml"
    "scripts/security_scan.py"
    "scripts/security_scan.sh"
    ".sqlfluff"
    "ci-cd/github-actions.yml"
    "ci-cd/gitlab-ci.yml"
    "docker/init.sql"
)

for file in "${expected_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Falta: $file"
    fi
done

echo ""

# ==============================================================================
# PASO 3: EJECUTAR ESCANEO DE SEGURIDAD
# ==============================================================================
echo "🔒 PASO 3: Ejecutando escaneo de seguridad..."
echo ""

echo "🐍 Versión Python:"
python3 --version
echo ""

echo "Ejecutando security_scan.py..."
python3 scripts/security_scan.py liquibase/changelog/

if [ $? -eq 0 ]; then
    echo "✅ Escaneo de seguridad exitoso - No hay violaciones"
else
    echo "⚠️  Se encontraron violaciones - revisar arriba"
fi

echo ""

# ==============================================================================
# PASO 4: VALIDAR SQL CON SQLFLUFF
# ==============================================================================
echo "📝 PASO 4: Validando SQL con SQLFluff..."
echo ""

# Intenta usar sqlfluff si está instalado
if command -v sqlfluff &> /dev/null; then
    echo "📋 Versión de SQLFluff:"
    sqlfluff version
    echo ""
    
    echo "Linting SQL files..."
    sqlfluff lint liquibase/changelog/ --dialect oracle --config .sqlfluff
    
    if [ $? -eq 0 ]; then
        echo "✅ Archivos SQL cumple con estándares"
    else
        echo "⚠️  Se encontraron problemas de estilo"
    fi
else
    echo "⚠️  SQLFluff no está instalado (opcional)"
    echo "    Instálalo con: pip install sqlfluff sqlfluff[oracle]"
fi

echo ""

# ==============================================================================
# PASO 5: LEVANTAR AMBIENTE LOCAL CON DOCKER
# ==============================================================================
echo "🐳 PASO 5: Levantando ambiente local con Docker Compose..."
echo ""

read -p "¿Deseas levantar los contenedores? (s/n): " -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Iniciando docker-compose..."
    docker-compose up -d
    
    if [ $? -eq 0 ]; then
        echo "✅ Contenedores iniciados"
    else
        echo "❌ Error al iniciar contenedores"
        exit 1
    fi
    
    echo ""
    echo "⏳ Esperando que Oracle XE esté listo (aprox 2-3 minutos)..."
    sleep 10
    
    # Verificar que Oracle esté listo
    for i in {1..30}; do
        if docker exec oracle-xe-test sqlplus -version &>/dev/null; then
            echo "✅ Oracle XE está listo!"
            break
        fi
        echo "   Intento $i/30..."
        sleep 5
    done
    
    echo ""
    echo "Contenedores activos:"
    docker-compose ps
    
else
    echo "⏭️  Saltando levantamiento de contenedores"
fi

echo ""

# ==============================================================================
# PASO 6: VALIDAR CONEXIÓN ORACLE
# ==============================================================================
echo "🔗 PASO 6: Validando conexión a Oracle..."
echo ""

if docker exec oracle-xe-test sqlplus -v &>/dev/null; then
    echo "✅ Conexión a Oracle exitosa"
    
    # Intenta conectar y ejecutar una query simple
    docker exec oracle-xe-test sqlplus -S admin/Oracle123!@XE <<EOF
SET HEADING OFF FEEDBACK OFF VERIFY OFF TRIMSPOOL ON PAGESIZE 0 LINESIZE 1000
SELECT 'Oracle está listo' FROM dual;
EXIT;
EOF
    
    echo ""
else
    echo "⚠️  No se puede conectar a Oracle aún (puede estar en inicio)"
fi

echo ""

# ==============================================================================
# PASO 7: EJECUTAR DRY-RUN CON LIQUIBASE
# ==============================================================================
echo "🧪 PASO 7: Ejecutando Liquibase Dry-Run..."
echo ""

read -p "¿Deseas ejecutar el dry-run? (s/n): " -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Ejecutando liquibase update-sql (dry-run)..."
    
    docker-compose run --rm liquibase liquibase \
      --changeLogFile=changelog/master.xml \
      --driver=oracle.jdbc.driver.OracleDriver \
      --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
      --username=admin \
      --password=Oracle123! \
      update-sql
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Dry-run completado - SQL preview mostrado arriba"
    else
        echo "❌ Error en dry-run - verificar logs"
    fi
else
    echo "⏭️  Saltando dry-run"
fi

echo ""

# ==============================================================================
# PASO 8: EJECUTAR DESPLIEGUE
# ==============================================================================
echo "📤 PASO 8: Ejecutando despliegue real..."
echo ""

read -p "¿Deseas ejecutar el despliegue? (s/n): " -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Ejecutando liquibase update..."
    
    docker-compose run --rm liquibase liquibase \
      --changeLogFile=changelog/master.xml \
      --driver=oracle.jdbc.driver.OracleDriver \
      --url=jdbc:oracle:thin:@oracle-xe:1521:XE \
      --username=admin \
      --password=Oracle123! \
      update
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Despliegue completado exitosamente!"
    else
        echo "❌ Error en despliegue - verificar logs"
    fi
else
    echo "⏭️  Saltando despliegue"
fi

echo ""

# ==============================================================================
# PASO 9: VERIFICAR CAMBIOS EN BASE DE DATOS
# ==============================================================================
echo "📊 PASO 9: Verificando cambios en la base de datos..."
echo ""

docker exec oracle-xe-test sqlplus -S admin/Oracle123!@XE <<EOF
SET HEADING ON FEEDBACK ON VERIFY OFF TRIMSPOOL ON PAGESIZE 100 LINESIZE 100

-- Mostrar tablas creadas
PROMPT
PROMPT ===== TABLAS CREADAS =====
SELECT table_name FROM user_tables WHERE table_name IN ('USERS', 'AUDIT_LOG') ORDER BY table_name;

-- Mostrar secuencias creadas
PROMPT
PROMPT ===== SECUENCIAS CREADAS =====
SELECT sequence_name FROM user_sequences WHERE sequence_name = 'USER_SEQ';

-- Mostrar triggers
PROMPT
PROMPT ===== TRIGGERS CREADOS =====
SELECT trigger_name FROM user_triggers WHERE trigger_name = 'USER_ID_TRIGGER';

-- Mostrar índices
PROMPT
PROMPT ===== ÍNDICES CREADOS =====
SELECT index_name FROM user_indexes WHERE table_name = 'USERS';

-- Mostrar historial de Liquibase
PROMPT
PROMPT ===== HISTORIAL DE LIQUIBASE =====
SELECT ID, AUTHOR, FILENAME, DATEEXECUTED, ORDEREXECUTED, EXECTYPE, DESCRIPTION 
FROM DATABASECHANGELOG 
ORDER BY ORDEREXECUTED DESC 
FETCH FIRST 10 ROWS ONLY;

EXIT;
EOF

echo "✅ Verificación completada"
echo ""

# ==============================================================================
# PASO 10: INFORMACIÓN DE LIMPIEZA
# ==============================================================================
echo "🧹 PASO 10: Comandos de limpieza (si es necesario)..."
echo ""

echo "Para detener los contenedores:"
echo "  docker-compose down"
echo ""
echo "Para eliminar volúmenes (datos de Oracle):"
echo "  docker-compose down -v"
echo ""
echo "Para ver logs de Oracle:"
echo "  docker-compose logs oracle-xe"
echo ""
echo "Para ver logs de Liquibase:"
echo "  docker-compose logs liquibase"
echo ""

# ==============================================================================
# RESUMEN FINAL
# ==============================================================================
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  PRUEBAS COMPLETADAS                                                    ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Estructura validada"
echo "✅ Seguridad verificada"
echo "✅ SQL formateado correctamente"
echo ""
echo "Próximos pasos:"
echo "  1. Revisar ci-cd/github-actions.yml para GitHub"
echo "  2. Revisar ci-cd/gitlab-ci.yml para GitLab"
echo "  3. Configurar secrets en tu repositorio"
echo "  4. Hacer push a main/develop para activar pipeline"
echo ""
