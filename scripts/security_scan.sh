#!/bin/bash
# Script de validación de políticas de seguridad (versión Bash)
# Alternativa a la versión Python para entornos sin Python

set -e

SCAN_DIR="${1:-.}"
FORBIDDEN_KEYWORDS=(
    "TRUNCATE"
    "DROP TABLE"
    "DROP SCHEMA"
    "DELETE FROM"
    "ANY PRIVILEGE"
    "GRANT.*TO PUBLIC"
    "BECOME USER"
    "CONNECT INTERNAL"
    "EXECUTE IMMEDIATE"
)

VIOLATION_COUNT=0
FOUND_VIOLATIONS=false

echo "🔍 Escaneando archivos SQL en: $SCAN_DIR"
echo "----------------------------------------"

for sql_file in $(find "$SCAN_DIR" -name "*.sql" -type f); do
    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))
        
        # Ignorar comentarios
        if [[ "$line" =~ ^[[:space:]]*-- ]] || [[ "$line" =~ ^[[:space:]]*/\* ]]; then
            continue
        fi
        
        for keyword in "${FORBIDDEN_KEYWORDS[@]}"; do
            if [[ "${line^^}" =~ $keyword ]]; then
                if [[ ! "${line^^}" =~ ROLLBACK ]] && [[ ! "${line^^}" =~ COMMENT ]]; then
                    echo "❌ Archivo: $sql_file"
                    echo "   Línea: $LINE_NUM"
                    echo "   Palabra clave: $keyword"
                    echo "   Contenido: $line"
                    echo ""
                    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
                    FOUND_VIOLATIONS=true
                fi
            fi
        done
    done < "$sql_file"
done

echo "----------------------------------------"

if [ "$FOUND_VIOLATIONS" = false ]; then
    echo "✅ No se encontraron violaciones de seguridad"
    exit 0
else
    echo "❌ Se encontraron $VIOLATION_COUNT violacion(es)"
    exit 1
fi
