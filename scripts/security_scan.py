#!/usr/bin/env python3
"""
Script de validación de políticas de seguridad para archivos SQL.
Escanea archivos .sql buscando palabras clave prohibidas y comandos peligrosos.
"""

import os
import re
import sys
from pathlib import Path

# Palabras clave prohibidas que indican operaciones peligrosas
FORBIDDEN_KEYWORDS = {
    'TRUNCATE': 'TRUNCATE elimina todos los registros sin generar logs de auditoría',
    'DROP TABLE': 'DROP TABLE puede eliminar esquemas completos sin recuperación',
    'DROP SCHEMA': 'DROP SCHEMA elimina esquemas completos',
    'DELETE FROM': 'DELETE sin WHERE puede eliminar datos críticos',
    'UPDATE': 'UPDATE sin WHERE puede modificar datos críticos',
    'ANY PRIVILEGE': 'ANY PRIVILEGE otorga permisos excesivos',
    'GRANT.*TO PUBLIC': 'Otorgar permisos a PUBLIC es un riesgo de seguridad',
    'BECOME USER': 'BECOME USER permite suplantación de usuarios',
    'CONNECT INTERNAL': 'CONNECT INTERNAL permite acceso no autorizado',
    'PASSWORD': 'Contraseñas en archivos SQL son un riesgo de seguridad',
    'SYS.': 'Acceso directo a objetos SYS es peligroso',
    'SYSTEM.': 'Acceso directo a objetos SYSTEM es peligroso',
    'AUDIT': 'Modificaciones a AUDIT deben ser limitadas',
    'EXECUTE IMMEDIATE': 'SQL dinámico sin validación es un riesgo de inyección',
}

def scan_sql_file(filepath):
    """
    Escanea un archivo SQL en busca de palabras clave prohibidas.
    Retorna lista de violaciones encontradas.
    """
    violations = []
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        return [{'line': 0, 'keyword': 'ERROR', 'message': f'No se pudo leer el archivo: {e}'}]
    
    for line_num, line in enumerate(lines, 1):
        # Ignorar comentarios
        if line.strip().startswith('--') or line.strip().startswith('/*'):
            continue
        
        line_upper = line.upper()
        
        for keyword, reason in FORBIDDEN_KEYWORDS.items():
            if re.search(r'\b' + keyword.replace(' ', r'\s+') + r'\b', line_upper):
                # Excepciones: permitir en comentarios o declaraciones de rollback
                if 'ROLLBACK' in line_upper or 'COMMENT' in line:
                    continue
                
                violations.append({
                    'file': filepath,
                    'line': line_num,
                    'keyword': keyword,
                    'content': line.strip(),
                    'reason': reason
                })
    
    return violations

def scan_directory(directory):
    """
    Escanea recursivamente todos los archivos .sql en un directorio.
    """
    all_violations = []
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.sql'):
                filepath = os.path.join(root, file)
                violations = scan_sql_file(filepath)
                all_violations.extend(violations)
    
    return all_violations

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 security_scan.py <directorio_sql>")
        print("Ejemplo: python3 security_scan.py ./liquibase/changelog")
        sys.exit(1)
    
    scan_dir = sys.argv[1]
    
    if not os.path.isdir(scan_dir):
        print(f"Error: '{scan_dir}' no es un directorio válido")
        sys.exit(1)
    
    print(f"🔍 Escaneando archivos SQL en: {scan_dir}")
    print("-" * 80)
    
    violations = scan_directory(scan_dir)
    
    if not violations:
        print("✅ No se encontraron violaciones de seguridad")
        return 0
    
    print(f"❌ Se encontraron {len(violations)} violacion(es) de seguridad:\n")
    
    for violation in violations:
        print(f"📄 Archivo: {violation['file']}")
        print(f"   Línea: {violation['line']}")
        print(f"   Palabra clave: {violation['keyword']}")
        print(f"   Contenido: {violation['content']}")
        print(f"   Razón: {violation['reason']}")
        print()
    
    print("-" * 80)
    print(f"Total de violaciones: {len(violations)}")
    
    return 1  # Exit con error si hay violaciones

if __name__ == '__main__':
    sys.exit(main())
