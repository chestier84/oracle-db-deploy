-- Script de inicialización de Oracle XE
-- Se ejecuta automáticamente cuando se levanta el contenedor

-- Crear tablespace temporal
CREATE TEMPORARY TABLESPACE temp_ts TEMPFILE '/opt/oracle/oradata/temp_ts.dbf' SIZE 100M REUSE AUTOEXTEND ON NEXT 10M;

-- Crear usuario de aplicación
CREATE USER appuser IDENTIFIED BY AppUser123! DEFAULT TABLESPACE users TEMPORARY TABLESPACE temp_ts;

-- Otorgar permisos básicos
GRANT CREATE SESSION TO appuser;
GRANT CREATE TABLE TO appuser;
GRANT CREATE SEQUENCE TO appuser;
GRANT CREATE PROCEDURE TO appuser;
GRANT CREATE TRIGGER TO appuser;

-- Crear usuario para Liquibase
CREATE USER liquibase_user IDENTIFIED BY Liquibase123! DEFAULT TABLESPACE users;
GRANT CREATE SESSION TO liquibase_user;
GRANT CREATE TABLE TO liquibase_user;
GRANT ALTER SESSION TO liquibase_user;
GRANT RESOURCE TO liquibase_user;

-- Crear directorio para logs
CREATE OR REPLACE DIRECTORY db_logs AS '/opt/oracle/oradata/logs';
GRANT READ, WRITE ON DIRECTORY db_logs TO appuser;

COMMIT;
