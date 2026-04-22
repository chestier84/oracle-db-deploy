# ========================================================================
# SCRIPT: Conectar repositorio Git local con GitHub remoto
# Version PowerShell para Windows
# ========================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  CONECTAR REPOSITORIO CON GITHUB                                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verificar que estamos en un repositorio Git
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: No estas en un repositorio Git" -ForegroundColor Red
    Write-Host "Navega a la carpeta oracle-db-deploy primero" -ForegroundColor Yellow
    exit 1
}

Write-Host "Paso 1: Ingresar nombre de usuario de GitHub" -ForegroundColor Yellow
Write-Host "Ejemplo: juan-oracle" -ForegroundColor Gray
$github_user = Read-Host "Username"

if ([string]::IsNullOrWhiteSpace($github_user)) {
    Write-Host "ERROR: Username vacio" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Paso 2: Nombre del repositorio en GitHub" -ForegroundColor Yellow
Write-Host "Ejemplo: oracle-db-deploy" -ForegroundColor Gray
$repo_name = Read-Host "Repository"

if ([string]::IsNullOrWhiteSpace($repo_name)) {
    Write-Host "ERROR: Repository vacio" -ForegroundColor Red
    exit 1
}

$remote_url = "https://github.com/$github_user/$repo_name.git"

Write-Host ""
Write-Host "Paso 3: Agregando repositorio remoto..." -ForegroundColor Yellow
Write-Host "   URL: $remote_url" -ForegroundColor Gray

# Verificar si remoto ya existe
try {
    $existing = git remote get-url origin 2>$null
    if ($existing) {
        Write-Host "   ADVERTENCIA: Ya existe un remoto 'origin'. Eliminando..." -ForegroundColor Yellow
        git remote remove origin
    }
} catch {
    # Sin remoto existente, continuar
}

# Agregar remoto
git remote add origin $remote_url

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo agregar remoto" -ForegroundColor Red
    exit 1
}

Write-Host "   OK: Remoto agregado" -ForegroundColor Green

Write-Host ""
Write-Host "Paso 4: Verificando conexion..." -ForegroundColor Yellow
git remote -v

Write-Host ""
Write-Host "Paso 5: Pusheando a GitHub..." -ForegroundColor Yellow
Write-Host "   (Se puede pedir credenciales)" -ForegroundColor Gray
Write-Host ""

git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  CONEXION EXITOSA ✅                                                    ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tu repositorio esta en:" -ForegroundColor Green
    Write-Host "  🔗 $remote_url" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Proximos pasos:" -ForegroundColor Yellow
    Write-Host "  1. Abre el enlace en tu navegador para verificar los archivos" -ForegroundColor Gray
    Write-Host "  2. Ve a Settings -> Secrets and variables -> Actions" -ForegroundColor Gray
    Write-Host "  3. Agrega los secrets: ORACLE_HOST, ORACLE_PORT, ORACLE_SID, etc." -ForegroundColor Gray
    Write-Host "  4. Haz cambios, commit y push para ver el pipeline ejecutarse" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Abre ahora: $remote_url" -ForegroundColor Cyan
    
    # Intentar abrir en navegador
    try {
        Start-Process $remote_url
        Write-Host "   ✅ Abriendo en navegador..." -ForegroundColor Green
    } catch {
        Write-Host "   Abre manualmente el enlace anterior" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "ADVERTENCIA: Hubo un error al pushear" -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifica:" -ForegroundColor Yellow
    Write-Host "  - Que tu repositorio existe en GitHub" -ForegroundColor Gray
    Write-Host "  - Tu username y token personal (si usas token)" -ForegroundColor Gray
    Write-Host "  - Tu conexion a internet" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Intenta nuevamente con:" -ForegroundColor Yellow
    Write-Host "  git push -u origin main" -ForegroundColor Cyan
    exit 1
}
