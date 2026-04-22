#!/bin/bash

# ========================================================================
# SCRIPT DE EXPORTACIÓN - Oracle DB Deployment Project
# ========================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  EXPORT ORACLE DATABASE DEPLOYMENT PROJECT                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""

PROJECT_NAME="oracle-db-deploy"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
EXPORT_DIR="exports"

# Crear directorio de exportación
mkdir -p "$EXPORT_DIR"

echo "📦 Opciones de exportación disponibles:"
echo ""
echo "1. ZIP (Recomendado para Windows)"
echo "2. TAR.GZ (Recomendado para Linux/Mac)"
echo "3. Git repository (GitHub/GitLab)"
echo "4. Docker image"
echo "5. Todas las opciones"
echo ""

read -p "Selecciona opción (1-5): " option

case $option in

    1)
        echo ""
        echo "Exportando como ZIP..."
        zip -r "$EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.zip" "$PROJECT_NAME/"
        echo "✅ Archivo creado: $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.zip"
        ;;

    2)
        echo ""
        echo "Exportando como TAR.GZ..."
        tar -czf "$EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz" "$PROJECT_NAME/"
        echo "✅ Archivo creado: $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
        ;;

    3)
        echo ""
        echo "Configurando Git repository..."
        cd "$PROJECT_NAME" || exit
        
        # Inicializar Git si no existe
        if [ ! -d .git ]; then
            git init
            git add .
            git commit -m "Initial commit: Oracle DB Deployment with Liquibase"
            git branch -M main
        fi
        
        echo ""
        echo "✅ Repositorio Git iniciado"
        echo ""
        echo "Próximos pasos:"
        echo "  1. Crear repositorio en GitHub/GitLab"
        echo "  2. Copiar URL del repositorio"
        echo "  3. Ejecutar:"
        echo "     git remote add origin <URL>"
        echo "     git push -u origin main"
        echo ""
        cd ..
        ;;

    4)
        echo ""
        echo "Creando Dockerfile..."
        
        # Crear Dockerfile
        cat > "$PROJECT_NAME/Dockerfile" <<'EOF'
FROM liquibase/liquibase:4.26.0

WORKDIR /liquibase

COPY liquibase /liquibase/
COPY scripts /scripts/

CMD ["liquibase", "update"]
EOF
        
        echo "Construyendo imagen Docker..."
        docker build -t "${PROJECT_NAME}:${TIMESTAMP}" "$PROJECT_NAME/"
        
        echo "Exportando imagen..."
        docker save "${PROJECT_NAME}:${TIMESTAMP}" | gzip > "$EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
        
        echo "✅ Imagen Docker creada: $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
        echo ""
        echo "Para importar en otro sistema:"
        echo "  docker load < $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
        ;;

    5)
        echo ""
        echo "Exportando en todas las opciones..."
        echo ""
        
        # ZIP
        echo "1. Creando ZIP..."
        zip -r "$EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.zip" "$PROJECT_NAME/" > /dev/null
        echo "   ✅ $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.zip"
        
        # TAR.GZ
        echo "2. Creando TAR.GZ..."
        tar -czf "$EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz" "$PROJECT_NAME/" > /dev/null
        echo "   ✅ $EXPORT_DIR/${PROJECT_NAME}_${TIMESTAMP}.tar.gz"
        
        # Git
        echo "3. Inicializando Git..."
        cd "$PROJECT_NAME" || exit
        if [ ! -d .git ]; then
            git init > /dev/null
            git add . > /dev/null
            git commit -m "Initial commit: Oracle DB Deployment with Liquibase" > /dev/null
            git branch -M main > /dev/null
        fi
        cd ..
        echo "   ✅ Git repository inicializado"
        
        # Docker
        echo "4. Creando imagen Docker..."
        cat > "$PROJECT_NAME/Dockerfile" <<'EOF'
FROM liquibase/liquibase:4.26.0
WORKDIR /liquibase
COPY liquibase /liquibase/
COPY scripts /scripts/
CMD ["liquibase", "update"]
EOF
        docker build -t "${PROJECT_NAME}:${TIMESTAMP}" "$PROJECT_NAME/" > /dev/null 2>&1
        docker save "${PROJECT_NAME}:${TIMESTAMP}" | gzip > "$EXPORT_DIR/${PROJECT_NAME}_docker_${TIMESTAMP}.tar.gz" 2>/dev/null
        echo "   ✅ Docker image exportada"
        
        echo ""
        echo "✅ Todas las exportaciones completadas en: $EXPORT_DIR/"
        ls -lh "$EXPORT_DIR/"
        ;;

    *)
        echo "Opción inválida"
        exit 1
        ;;

esac

echo ""
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║  EXPORTACIÓN COMPLETADA                                                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo ""
