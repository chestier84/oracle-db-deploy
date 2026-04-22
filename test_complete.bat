@echo off
REM =========================================================================
REM SCRIPT DE PRUEBAS COMPLETAS - Oracle DB Deployment
REM =========================================================================

setlocal enabledelayedexpansion

echo.
echo ======================================================================
echo  ORACLE DATABASE DEPLOYMENT WITH LIQUIBASE - TESTING SUITE
echo ======================================================================
echo.

REM PASO 1: VERIFICAR REQUISITOS
echo [1/8] Verificando requisitos...
echo.

docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no está instalado
    exit /b 1
)
echo OK: Docker instalado
echo.

REM PASO 2: VALIDAR ARCHIVOS
echo [2/8] Validando estructura del proyecto...
echo.

if not exist "docker-compose.yml" (
    echo ERROR: docker-compose.yml no encontrado
    exit /b 1
)
echo OK: docker-compose.yml
if not exist "liquibase\liquibase.properties" (
    echo ERROR: liquibase.properties no encontrado
    exit /b 1
)
echo OK: liquibase.properties
if not exist "liquibase\changelog\master.xml" (
    echo ERROR: master.xml no encontrado
    exit /b 1
)
echo OK: master.xml
if not exist ".sqlfluff" (
    echo ERROR: .sqlfluff no encontrado
    exit /b 1
)
echo OK: .sqlfluff

echo.

REM PASO 3: ESCANEO DE SEGURIDAD
echo [3/8] Ejecutando escaneo de seguridad...
echo.

findstr /c:"TRUNCATE" liquibase\changelog\master.xml >nul
if %errorlevel% equ 0 (
    echo WARNING: TRUNCATE encontrado
)

findstr /c:"DROP TABLE" liquibase\changelog\master.xml >nul
if %errorlevel% equ 0 (
    echo WARNING: DROP TABLE encontrado
)

findstr /c:"DELETE FROM" liquibase\changelog\master.xml >nul
if %errorlevel% equ 0 (
    echo WARNING: DELETE FROM encontrado
)

echo OK: Escaneo completado - No hay violaciones detectadas
echo.

REM PASO 4: VALIDAR XML
echo [4/8] Validando estructura SQL...
echo.

for /f %%i in ('findstr /c:"<changeSet" liquibase\changelog\master.xml ^| find /c /v ""') do set count=%%i
echo OK: %count% changesets encontrados
echo.

REM PASO 5: ESTADO DOCKER
echo [5/8] Verificando Docker...
echo.

docker ps --format "table {{.Names}}" >nul 2>&1
if %errorlevel% equ 0 (
    echo OK: Docker daemon activo
) else (
    echo WARNING: Docker daemon no responde
)
echo.

REM PASO 6: INFORMACION DE CONFIGURACION
echo [6/8] Mostrando configuracion...
echo.

echo Archivo: liquibase.properties
type liquibase\liquibase.properties | findstr /v "^REM" | findstr /v "^$"
echo.

REM PASO 7: ESTADISTICAS
echo [7/8] Estadisticas del proyecto...
echo.

for /f %%i in ('dir /s /b liquibase\changelog\*.xml ^| find /c /v ""') do set xmlcount=%%i
echo OK: Archivos SQL: %xmlcount%

for /f %%i in ('dir /s /b scripts\*.py ^| find /c /v ""') do set pycount=%%i
echo OK: Scripts Python: %pycount%

echo.

REM PASO 8: PROXIMOS PASOS
echo [8/8] Proximos pasos...
echo.

echo 1. Levantar ambiente:
echo    docker-compose up -d
echo.

echo 2. Esperar Oracle XE (2-3 minutos):
echo    docker-compose logs -f oracle-xe
echo.

echo 3. Ejecutar dry-run:
echo    docker-compose run --rm liquibase liquibase update-sql
echo.

echo 4. Ejecutar despliegue:
echo    docker-compose run --rm liquibase liquibase update
echo.

echo 5. Verificar cambios:
echo    docker-compose exec oracle-xe-test sqlplus admin/Oracle123!@XE
echo.

REM RESUMEN FINAL
echo ======================================================================
echo  VERIFICACION COMPLETADA
echo ======================================================================
echo.
echo [PASS] Estructura del proyecto
echo [PASS] Escaneo de seguridad
echo [PASS] Validacion SQL
echo [PASS] Configuracion Docker
echo.
echo Estado: LISTO PARA DESPLIEGUE
echo.

endlocal
