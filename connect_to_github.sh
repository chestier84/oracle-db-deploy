#!/bin/bash

# ========================================================================
# SCRIPT: Conectar repositorio Git local con GitHub remoto
# ========================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  CONECTAR REPOSITORIO CON GITHUB                                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d ".git" ]; then
    echo "❌ Error: No estás en un repositorio Git"
    echo "Navega a la carpeta oracle-db-deploy primero"
    exit 1
fi

echo "1. Ingresar nombre de usuario de GitHub:"
read -p "Username (ej: juan-oracle): " github_user

if [ -z "$github_user" ]; then
    echo "❌ Error: Username vacío"
    exit 1
fi

# Validar que el repositorio existe
echo ""
echo "Verificando repositorio en GitHub..."
REPO_URL="https://api.github.com/users/$github_user/repos"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$REPO_URL")

if [ "$HTTP_CODE" != "200" ]; then
    echo "⚠️  No se pudo verificar el usuario. Continuando de todas formas..."
fi

# Preguntar nombre del repositorio
echo ""
echo "2. Nombre del repositorio en GitHub:"
read -p "Repository (ej: oracle-db-deploy): " repo_name

if [ -z "$repo_name" ]; then
    echo "❌ Error: Repository vacío"
    exit 1
fi

# Construir URL
REMOTE_URL="https://github.com/$github_user/$repo_name.git"

echo ""
echo "3. Agregando repositorio remoto..."
echo "   URL: $REMOTE_URL"

# Verificar si remoto ya existe
if git remote get-url origin &> /dev/null; then
    echo "⚠️  Ya existe un remoto 'origin'. Eliminando..."
    git remote remove origin
fi

# Agregar remoto
git remote add origin "$REMOTE_URL"

if [ $? -ne 0 ]; then
    echo "❌ Error al agregar remoto"
    exit 1
fi

echo "✅ Remoto agregado correctamente"

echo ""
echo "4. Verificando conexión..."
git remote -v

echo ""
echo "5. Pusheando a GitHub..."
echo "   (Puede pedir credenciales)"
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════════╗"
    echo "║  ✅ CONEXIÓN EXITOSA                                                    ║"
    echo "╚══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Tu repositorio está en:"
    echo "  🔗 $REMOTE_URL"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Ir a GitHub y verificar que los archivos aparecen"
    echo "  2. Configurar Secrets en Settings → Secrets and variables → Actions"
    echo "  3. Hacer cambios, commit y push"
    echo ""
else
    echo ""
    echo "⚠️  Hubo un error al pushear. Verifica:"
    echo "  - Que tu repositorio existe en GitHub"
    echo "  - Tu username y token personal"
    echo "  - Conexión a internet"
    exit 1
fi
