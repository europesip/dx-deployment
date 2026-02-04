/****************************************************************************************************
 * SCRIPT ADAPTED FROM HCL (ORIGINAL STRUCTURE PRESERVED)
 * Environment: Oracle 19c PDB (WPSDB)
 ****************************************************************************************************/

ALTER SESSION SET CONTAINER = WPSDB;

CREATE ROLE WP_CONFIG_USERS NOT IDENTIFIED;
GRANT CREATE TABLE,
        CREATE SESSION,
        CREATE SEQUENCE,
        CREATE TRIGGER,
        CREATE TYPE,
        CREATE VIEW
        TO WP_CONFIG_USERS;

GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_CONFIG_USERS;

--------------------------------------------------------------
-- SETUP for schema RELEASE
--------------------------------------------------------------
CREATE USER release
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;

GRANT WP_CONFIG_USERS TO release;

--------------------------------------------------------------
-- SETUP for schema COMMUNITY
--------------------------------------------------------------
CREATE USER community
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;

GRANT WP_CONFIG_USERS TO community;

--------------------------------------------------------------
-- SETUP for schema CUSTOMIZATION
--------------------------------------------------------------
CREATE USER customization
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;

GRANT WP_CONFIG_USERS TO customization;

--------------------------------------------------------------
-- SETUP for schema JCR
--------------------------------------------------------------
CREATE USER jcr
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;

GRANT WP_CONFIG_USERS TO jcr;


--------------------------------------------------------------
-- SETUP for schema FEEDBACK
--------------------------------------------------------------
CREATE USER feedback
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;


GRANT WP_CONFIG_USERS TO feedback;

--------------------------------------------------------------
-- SETUP for schema LIKEMINDS
--------------------------------------------------------------
CREATE USER likeminds
        IDENTIFIED BY Passw0rd
        DEFAULT TABLESPACE USERS
        TEMPORARY TABLESPACE TEMP;

GRANT WP_CONFIG_USERS TO likeminds;

--------------------------------------------------------------
-- TABLESPACE CREATION
--------------------------------------------------------------
-- Create a TABLESPACE
-- Updated with the database directory path for your Oracle version.
CREATE TABLESPACE ICMLFQ32
    DATAFILE '/u01/app/oracle/oradata/ORCL/WPSDB/ICMLFQ32.dbf' SIZE 300M
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMLNF32
    DATAFILE '/u01/app/oracle/oradata/ORCL/WPSDB/ICMLNF32.dbf' SIZE 25M
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMVFQ04
    DATAFILE '/u01/app/oracle/oradata/ORCL/WPSDB/ICMVFQ04.dbf' SIZE 25M
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMSFQ04
    DATAFILE '/u01/app/oracle/oradata/ORCL/WPSDB/ICMSFQ04.dbf' SIZE 150M
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

CREATE TABLESPACE ICMLSNDX
    DATAFILE '/u01/app/oracle/oradata/ORCL/WPSDB/ICMLSNDX.dbf' SIZE 10M
    AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

--------------------------------------------------------------
-- QUOTAS (Replaces GRANT UNLIMITED TABLESPACE)
--------------------------------------------------------------

-- 1. Quotas on the default tablespace (USERS) for all users
ALTER USER release QUOTA UNLIMITED ON USERS;
ALTER USER community QUOTA UNLIMITED ON USERS;
ALTER USER customization QUOTA UNLIMITED ON USERS;
ALTER USER jcr QUOTA UNLIMITED ON USERS;
ALTER USER feedback QUOTA UNLIMITED ON USERS;
ALTER USER likeminds QUOTA UNLIMITED ON USERS;

-- 2. Quotas on specific tablespaces (ICM...)
-- Typically, these are used by the JCR user or the content management user.
-- Granting to 'jcr' user to ensure proper access to these segments.

ALTER USER jcr QUOTA UNLIMITED ON ICMLFQ32;
ALTER USER jcr QUOTA UNLIMITED ON ICMLNF32;
ALTER USER jcr QUOTA UNLIMITED ON ICMVFQ04;
ALTER USER jcr QUOTA UNLIMITED ON ICMSFQ04;
ALTER USER jcr QUOTA UNLIMITED ON ICMLSNDX;