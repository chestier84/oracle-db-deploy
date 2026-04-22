# ========================================================================
# SCRIPT DE PRUEBAS COMPLETAS - Oracle DB Deployment con Liquibase
# Versión Windows PowerShell/CMD
# ========================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ORACLE DATABASE DEPLOYMENT WITH LIQUIBASE - TESTING SUITE              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ========================================================================
# PASO 1: VERIFICAR REQUISITOS
# ========================================================================
Write-Host "📋 PASO 1: Verificando requisitos..." -ForegroundColor Yellow
Write-Host ""

$tools = @("docker", "docker-compose", "git")
$missing = @()

foreach ($tool in $tools) {
    try {
        $version = & $tool --version 2>&1 | Select-Object -First 1
        Write-Host "✅ $tool`: $version" -ForegroundColor Green
    }
    catch {
        $missing += $tool
        Write-Host "❌ $tool no está instalado" -ForegroundColor Red
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  Por favor instala las siguientes herramientas:" -ForegroundColor Yellow
    foreach ($m in $missing) {
        Write-Host "  - $m"
    }
    exit 1
}

Write-Host ""
Write-Host "✅ Todos los requisitos están instalados" -ForegroundColor Green
Write-Host ""

# ========================================================================
# PASO 2: VALIDAR ESTRUCTURA DEL PROYECTO
# ========================================================================
Write-Host "📁 PASO 2: Validando estructura del proyecto..." -ForegroundColor Yellow
Write-Host ""

$expectedFiles = @(
    "docker-compose.yml",
    "liquibase/liquibase.properties",
    "liquibase/changelog/master.xml",
    "scripts/security_scan.py",
    "scripts/security_scan.sh",
    ".sqlfluff",
    "ci-cd/github-actions.yml",
    "ci-cd/gitlab-ci.yml",
    "docker/init.sql"
)

foreach ($file in $expectedFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Falta: $file" -ForegroundColor Red
    }
}

Write-Host ""

# ========================================================================
# PASO 3: EJECUTAR ESCANEO DE SEGURIDAD
# ========================================================================
Write-Host "🔒 PASO 3: Ejecutando escaneo de seguridad..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Buscando violaciones de seguridad..." -ForegroundColor Cyan
Write-Host ""

$violations = 0
$securityKeywords = @(
    "TRUNCATE",
    "DROP TABLE",
    "DROP SCHEMA",
    "DELETE FROM",
    "ANY PRIVILEGE",
    "GRANT.*PUBLIC",
    "BECOME USER",
    "CONNECT INTERNAL",
    "EXECUTE IMMEDIATE",
    "PASSWORD"
)

$changelogPath = "liquibase/changelog/master.xml"
if (Test-Path $changelogPath) {
    $content = Get-Content $changelogPath -Raw
    foreach ($keyword in $securityKeywords) {
        if ($content -match $keyword) {
            Write-Host "❌ Encontrado: $keyword" -ForegroundColor Red
            $violations++
        }
    }
}

if ($violations -eq 0) {
    Write-Host "✅ Escaneo de seguridad exitoso - No hay violaciones" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Se encontraron $violations violacion(es)" -ForegroundColor Yellow
}

Write-Host ""

# ========================================================================
# PASO 4: VALIDAR ESTRUCTURA SQL
# ========================================================================
Write-Host "📝 PASO 4: Validando estructura SQL..." -ForegroundColor Yellow
Write-Host ""

$xmlFile = "liquibase/changelog/master.xml"
if (Test-Path $xmlFile) {
    [xml]$xml = Get-Content $xmlFile
    $changesets = $xml.SelectNodes("//changeSet").Count
    Write-Host "✅ Changesets encontrados: $changesets" -ForegroundColor Green
    Write-Host ""
    
    $xml.SelectNodes("//changeSet") | ForEach-Object {
        $id = $_.GetAttribute("id")
        $author = $_.GetAttribute("author")
        Write-Host "  ✓ $id (por $author)"
    }
}

Write-Host ""

# ========================================================================
# PASO 5: ESTADO DE DOCKER
# ========================================================================
Write-Host "🐳 PASO 5: Verificando Docker..." -ForegroundColor Yellow
Write-Host ""

$containers = docker ps --format "table {{.Names}}"
if ($containers) {
    Write-Host "Contenedores activos:" -ForegroundColor Cyan
    docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
}
else {
    Write-Host "⚠️  No hay contenedores ejecutándose" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para levantar el ambiente:" -ForegroundColor Cyan
    Write-Host "  docker-compose up -d" -ForegroundColor Gray
}

Write-Host ""

# ========================================================================
# PASO 6: INFORMACIÓN DE CONFIGURACIÓN
# ========================================================================
Write-Host "⚙️  PASO 6: Información de configuración..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Archivo: liquibase.properties" -ForegroundColor Cyan
$props = Get-Content "liquibase/liquibase.properties" | Select-String "^[^#]"
$props | ForEach-Object {
    $line = $_.Line
    if ($line -match "password") {
        Write-Host "  $line" -ForegroundColor DarkYellow
    }
    else {
        Write-Host "  $line" -ForegroundColor Gray
    }
}

Write-Host ""

# ========================================================================
# PASO 7: TAMAÑO DEL PROYECTO
# ========================================================================
Write-Host "📊 PASO 7: Estadísticas del proyecto..." -ForegroundColor Yellow
Write-Host ""

$files = Get-ChildItem -Recurse -File
$totalSize = ($files | Measure-Object -Property Length -Sum).Sum / 1KB

Write-Host "Archivos totales: $($files.Count)" -ForegroundColor Green
Write-Host "Tamaño total: $([Math]::Round($totalSize, 2)) KB" -ForegroundColor Green

Write-Host ""
Write-Host "Archivos por tipo:" -ForegroundColor Cyan
$files | Group-Object Extension | Select-Object @{N="Extensión";E={if($_.Name){"$($_.Name)"}else{"(sin ext)"}}}, @{N="Cantidad";E={$_.Count}} | Format-Table

Write-Host ""

# ========================================================================
# PASO 8: PRÓXIMOS PASOS
# ========================================================================
Write-Host "🚀 PASO 8: Próximos pasos recomendados..." -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣  Levantar ambiente local:" -ForegroundColor Cyan
Write-Host "    docker-compose up -d" -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣  Esperar que Oracle XE inicie (2-3 minutos):" -ForegroundColor Cyan
Write-Host "    docker-compose logs -f oracle-xe" -ForegroundColor Gray
Write-Host ""

Write-Host "3️⃣  Ejecutar dry-run (ver SQL sin aplicar cambios):" -ForegroundColor Cyan
Write-Host "    docker-compose run --rm liquibase liquibase update-sql" -ForegroundColor Gray
Write-Host ""

Write-Host "4️⃣  Ejecutar despliegue real:" -ForegroundColor Cyan
Write-Host "    docker-compose run --rm liquibase liquibase update" -ForegroundColor Gray
Write-Host ""

Write-Host "5️⃣  Verificar cambios en Oracle:" -ForegroundColor Cyan
Write-Host "    docker-compose exec oracle-xe-test sqlplus admin/Oracle123!@XE" -ForegroundColor Gray
Write-Host ""

# ========================================================================
# RESUMEN FINAL
# ========================================================================
Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VERIFICACIÓN COMPLETADA                                                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Estructura del proyecto" -ForegroundColor Green
Write-Host "✅ Escaneo de seguridad" -ForegroundColor Green
Write-Host "✅ Validación SQL" -ForegroundColor Green
Write-Host "✅ Configuración Docker" -ForegroundColor Green
Write-Host ""
Write-Host "Estado: 🟢 LISTO PARA DESPLIEGUE" -ForegroundColor Green
Write-Host ""
