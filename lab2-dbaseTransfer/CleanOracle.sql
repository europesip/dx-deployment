/*******************************************************************************
 * SCRIPT DE LIMPIEZA TOTAL (WIPE) - WPSDB
 * Advertencia: Esto BORRARÁ todos los datos de HCL DX.
 *******************************************************************************/

-- 1. Entrar en el apartamento
ALTER SESSION SET CONTAINER = WPSDB;

-- 2. Borrar Usuarios (CASCADE elimina también sus tablas)
-- Usamos una sintaxis que no falla si el usuario no existe (PL/SQL) o
-- simplemente lanzamos los comandos y si dan error "no existe", mejor.
--------------------------------------------------------------------------------

-- Intentar borrar usuarios. Si sale "User does not exist", ignóralo.
DROP USER wpsuser CASCADE;
DROP USER jcr CASCADE;
DROP USER release CASCADE;
DROP USER community CASCADE;
DROP USER customization CASCADE;
DROP USER feedback CASCADE;
DROP USER likeminds CASCADE;

-- 3. Borrar Roles
--------------------------------------------------------------------------------
DROP ROLE WP_BASE_CONFIG_USERS;
DROP ROLE WP_BASE_RUNTIME_USERS;
DROP ROLE WP_JCR_CONFIG_USERS;
DROP ROLE WP_JCR_RUNTIME_USERS;
DROP ROLE WP_PZN_CONFIG_USERS;
DROP ROLE WP_PZN_RUNTIME_USERS;

-- 4. Borrar Tablespaces y sus ficheros físicos (.dbf)
-- Esto liberará el espacio en disco en /u01/...
--------------------------------------------------------------------------------
DROP TABLESPACE ICMLFQ32 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE ICMLNF32 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE ICMVFQ04 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE ICMSFQ04 INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE ICMLSNDX INCLUDING CONTENTS AND DATAFILES;

/*******************************************************************************
 * FIN DE LA LIMPIEZA
 * Ahora tu PDB 'WPSDB' está limpia y lista para correr el script de instalación.
 *******************************************************************************/