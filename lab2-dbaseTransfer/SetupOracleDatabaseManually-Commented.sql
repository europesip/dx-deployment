/****************************************************************************************************
 * HCL DX COMPOSE – ORACLE 19c DATABASE SETUP SCRIPT
 *
 * This script prepares an Oracle 19c database for use with
 * HCL Digital Experience (DX) Compose running on OpenLiberty.
 *
 * RECOMMENDED ARCHITECTURE (HCL BEST PRACTICE):
 * - Oracle 19c
 * - Multitenant architecture (CDB / PDB)
 * - ONE technical database user for DX connections
 * - ONE schema (Oracle user) per DX component
 * - Access control based on Oracle ROLES
 *
 * IMPORTANT ORACLE CONCEPTS:
 * - In Oracle, USER = SCHEMA
 * - DX DOES NOT connect using each schema owner
 * - DX connects using ONE technical user
 * - That technical user accesses all schemas via ROLES
 *
 * This script must be executed as SYS or SYSTEM.
 ****************************************************************************************************/


/****************************************************************************************************
 * STEP 0 – MULTITENANT / PDB CONTEXT (CRITICAL)
 *
 * Oracle 19c typically runs in MULTITENANT mode:
 * - CDB (Container Database): root container
 * - PDB (Pluggable Database): application-level database
 *
 * DX MUST NOT be installed in CDB$ROOT.
 * All users, roles and objects must be created in the target PDB.
 *
 * If your environment IS multitenant:
 *   - Replace WPSDB with the actual PDB name
 *   - Keep this statement
 *
 * If your environment is NOT multitenant:
 *   - REMOVE this statement completely
 ****************************************************************************************************/
ALTER SESSION SET CONTAINER = WPSDB;


/****************************************************************************************************
 * STEP 1 – TECHNICAL CONNECTION USER (DX JDBC USER)
 *
 * This is the ONLY user DX will use to connect via JDBC.
 * It is NOT the owner of the DX tables.
 * It receives privileges via ROLES to operate on other schemas.
 ****************************************************************************************************/
CREATE USER wpsuser IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;

GRANT CONNECT, RESOURCE TO wpsuser;

/*
 * DX requires elevated privileges for:
 * - initial schema creation
 * - internal jobs and timers
 * - maintenance and cleanup tasks
 *
 * HCL recommends granting DBA to the DX technical user.
 */
GRANT DBA TO wpsuser;


/****************************************************************************************************
 * STEP 2 – BASE ROLES (CORE DX COMPONENTS)
 * Used by: release, community, customization
 ****************************************************************************************************/
CREATE ROLE WP_BASE_CONFIG_USERS NOT IDENTIFIED;

GRANT
  ALTER ANY TABLE, CREATE ANY TABLE, DROP ANY TABLE,
  CREATE ANY INDEX, DROP ANY INDEX,
  INSERT ANY TABLE, UPDATE ANY TABLE, SELECT ANY TABLE, DELETE ANY TABLE,
  CREATE SESSION,
  CREATE ANY SEQUENCE, DROP ANY SEQUENCE
TO WP_BASE_CONFIG_USERS;

GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_BASE_CONFIG_USERS;


CREATE ROLE WP_BASE_RUNTIME_USERS NOT IDENTIFIED;

GRANT CREATE SESSION TO WP_BASE_RUNTIME_USERS;
GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_BASE_RUNTIME_USERS;


/****************************************************************************************************
 * STEP 3 – PERSONALIZATION ROLES
 * Used by: feedback, likeminds
 ****************************************************************************************************/
CREATE ROLE WP_PZN_CONFIG_USERS NOT IDENTIFIED;

GRANT
  ALTER ANY TABLE, CREATE ANY TABLE, DROP ANY TABLE,
  CREATE ANY INDEX, DROP ANY INDEX,
  INSERT ANY TABLE, UPDATE ANY TABLE, SELECT ANY TABLE, DELETE ANY TABLE,
  CREATE SESSION,
  CREATE ANY SEQUENCE, DROP ANY SEQUENCE
TO WP_PZN_CONFIG_USERS;

GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_PZN_CONFIG_USERS;


CREATE ROLE WP_PZN_RUNTIME_USERS NOT IDENTIFIED;

GRANT CREATE SESSION TO WP_PZN_RUNTIME_USERS;
GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_PZN_RUNTIME_USERS;


/****************************************************************************************************
 * STEP 4 – JCR-SPECIFIC ROLES
 *
 * JCR is the most demanding DX component:
 * - large tables
 * - complex indexes
 * - triggers, views, types
 ****************************************************************************************************/
CREATE ROLE WP_JCR_CONFIG_USERS NOT IDENTIFIED;

GRANT
  ALTER ANY TABLE, CREATE ANY TABLE, DROP ANY TABLE,
  CREATE ANY INDEX, DROP ANY INDEX,
  INSERT ANY TABLE, UPDATE ANY TABLE, SELECT ANY TABLE, DELETE ANY TABLE,
  CREATE SESSION,
  CREATE TABLESPACE, DROP TABLESPACE,
  CREATE ANY SEQUENCE, DROP ANY SEQUENCE,
  CREATE ANY TRIGGER, DROP ANY TRIGGER,
  CREATE ANY TYPE, DROP ANY TYPE, EXECUTE ANY TYPE,
  CREATE ANY VIEW, DROP ANY VIEW
TO WP_JCR_CONFIG_USERS;

GRANT SELECT ON DBA_IND_COLUMNS TO WP_JCR_CONFIG_USERS;
GRANT SELECT ON DBA_INDEXES TO WP_JCR_CONFIG_USERS;
GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_JCR_CONFIG_USERS;


CREATE ROLE WP_JCR_RUNTIME_USERS NOT IDENTIFIED;

GRANT CREATE SESSION TO WP_JCR_RUNTIME_USERS;
GRANT SELECT ON DBA_PENDING_TRANSACTIONS TO WP_JCR_RUNTIME_USERS;


/****************************************************************************************************
 * STEP 5 – DX SCHEMA OWNERS (ONE USER PER SCHEMA)
 *
 * Each user represents ONE schema.
 * DX will NOT connect using these users.
 * They are logical owners of the database objects.
 ****************************************************************************************************/
CREATE USER release IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO release;

CREATE USER community IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO community;

CREATE USER customization IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO customization;

CREATE USER feedback IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO feedback;

CREATE USER likeminds IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO likeminds;

CREATE USER jcr IDENTIFIED BY Passw0rd
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP;
GRANT UNLIMITED TABLESPACE TO jcr;


/****************************************************************************************************
 * STEP 6 – ROLE ASSIGNMENT TO DX TECHNICAL USER
 *
 * This is the core of the model:
 * - DX connects as wpsuser
 * - wpsuser has roles that allow access to ALL schemas
 ****************************************************************************************************/
GRANT WP_BASE_CONFIG_USERS TO wpsuser;
GRANT WP_BASE_RUNTIME_USERS TO wpsuser;
GRANT WP_PZN_CONFIG_USERS TO wpsuser;
GRANT WP_PZN_RUNTIME_USERS TO wpsuser;
GRANT WP_JCR_CONFIG_USERS TO wpsuser;
GRANT WP_JCR_RUNTIME_USERS TO wpsuser;


/****************************************************************************************************
 * END OF SCRIPT
 *
 * After execution:
 * - Oracle is fully prepared for DX Compose
 * - Schemas will be populated automatically on DX startup
 * - Objects will appear as:
 *     release.WP_*
 *     community.WP_*
 *     jcr.ICM*
 *
 * DX will ALWAYS connect using the wpsuser account.
 ****************************************************************************************************/
