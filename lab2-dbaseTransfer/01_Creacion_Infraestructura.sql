/****************************************************************************************************
 * SCRIPT 1: INFRAESTRUCTURA DE BASE DE DATOS
 * OBJETIVO: Creación de Tablespaces, Roles y Usuarios (Esquemas).
 * * ★★★★★ IMPORTANT WARNING ★★★★★
 * PLEASE REVIEW AND UPDATE ALL PATHS AND PASSWORDS ACCORDING TO YOUR ENVIRONMENT.
 * Modify <replace-with-user> and <replace-with-user-password> before execution.
 ****************************************************************************************************/

--------------------------------------------------------------
-- 1. TABLESPACE CREATION
-- Note: DBAs should review DATAFILE paths and sizing policies.
--------------------------------------------------------------
CREATE TABLESPACE ICMLFQ32 
    DATAFILE SIZE 300M 
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMLNF32 
    DATAFILE SIZE 25M 
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMVFQ04 
    DATAFILE SIZE 25M 
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMSFQ04 
    DATAFILE SIZE 150M 
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMLSNDX 
    DATAFILE SIZE 10M 
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED 
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

--------------------------------------------------------------
-- 2. ROLE CREATION
-- Definition of logical groups for permissions
--------------------------------------------------------------
CREATE ROLE WP_BASE_CONFIG_USERS NOT IDENTIFIED;
CREATE ROLE WP_BASE_RUNTIME_USERS NOT IDENTIFIED;

CREATE ROLE WP_JCR_CONFIG_USERS NOT IDENTIFIED;
CREATE ROLE WP_JCR_RUNTIME_USERS NOT IDENTIFIED;

CREATE ROLE WP_PZN_CONFIG_USERS NOT IDENTIFIED;
CREATE ROLE WP_PZN_RUNTIME_USERS NOT IDENTIFIED;

--------------------------------------------------------------
-- 3. USER CREATION
-- Creation of the technical user and schemas
--------------------------------------------------------------

-- Technical connection user
CREATE USER <replace-with-user> 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

-- Schemas
CREATE USER release 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

CREATE USER community 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

CREATE USER customization 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

CREATE USER jcr 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

CREATE USER feedback 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP; 

CREATE USER likeminds 
	IDENTIFIED BY <replace-with-user-password> 
	DEFAULT TABLESPACE USERS 
	TEMPORARY TABLESPACE TEMP;
