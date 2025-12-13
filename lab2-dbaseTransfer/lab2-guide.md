# 🚀 HCL DX Compose: Doing a DBTransfer

## Lab Guide (DX 9.5 CF231)

> **⚠️ DRAFT – Content Under Development**
> This lab guide is not yet finalized. Instructions may change as the content evolves.

This lab explains the operational steps required to deploy an external DB2 database and perform a Database Transfer (DBTransfer) for HCL DX.

---

## 📚 Official Documentation

➡️ **HCL DX Documentation – Database Management**
<https://help.hcl-software.com/digital-experience/dx-compose/CF231/deploy_dx/manage/cfg_webengine/external_db_database_transfer/>

---

## 1. Objective

This guide provides the required steps to:

* Prepare an external **DB2 Database** for HCL DX.
* Configure the **DBTransfer** process via Helm to migrate data from the internal Derby database to DB2.

### 1.1 Prerequisites

* A fully functional **DX Compose** installation (complete Lab 1 first).
* Permissions as `dxadmin` (or equivalent) on the OpenShift cluster.
* **Helm** installed and configured on your workstation.
* Access to an external DB2 server with a user capable of creating databases and schemas.
* The `SetupDb2DatabaseManually.sql` script available on your local machine.

> **Note:** This lab covers *operational setup only*. Any performance tuning or custom configuration must be applied via your own `custom-values.yaml`.

---

## 2. Server-Side Configuration (DB2)

### 2.1 Copy Script to the Database Server

Transfer the setup script from your local machine to the remote DB2 server.

```bash
scp SetupDb2DatabaseManually.sql db2inst1@db2.europesip-lab.com:~
```

### 2.2 Connect and Create OS Groups

Connect to the server via SSH. Note that creating groups requires `root` or `sudo` privileges.

```bash
ssh db2inst1@db2.europesip-lab.com
```

Once connected, create the necessary Operating System groups and assign the DB2 user to them. These groups are required for the permission grants in the SQL script.

Si db2inst1 tiene sudo, usa sudo. Si no, cambia a root con 'su -'

```bash
sudo groupadd WP_BASE_CONFIG_USERS ;
sudo groupadd WP_JCR_CONFIG_USERS  ;
sudo groupadd WP_PZN_CONFIG_USERS
```


Añadir al usuario db2inst1 a estos grupos para evitar problemas de permisos
```bash
sudo usermod -aG WP_BASE_CONFIG_USERS,WP_JCR_CONFIG_USERS,WP_PZN_CONFIG_USERS db2inst1
```

### 2.3 Create the Database and JCR Tablespaces

Execute the following commands as the `db2inst1` user to initialize the database environment.

```bash
# Ensure the DB2 instance is started
db2start ;

# 1. Create the WPSDB database (UTF-8 and 32k Pagesize are mandatory for DX) ;
db2 "CREATE DATABASE WPSDB AUTOMATIC STORAGE YES USING CODESET UTF-8 TERRITORY US PAGESIZE 32768" ;

# 2. Connect to the database ;
db2 connect to WPSDB ;

# 3. Create necessary Bufferpools (4k and 32k) ;
db2 "CREATE BUFFERPOOL ICML04KBP SIZE 1000 PAGESIZE 4K" ;
db2 "CREATE BUFFERPOOL ICML32KBP SIZE 1000 PAGESIZE 32K" ;

# 4. Create JCR Tablespaces (Required before running the setup script) ;
db2 "CREATE REGULAR TABLESPACE ICMLFQ32 PAGESIZE 32K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML32KBP" ;
db2 "CREATE REGULAR TABLESPACE ICMLNF32 PAGESIZE 32K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML32KBP" ;
db2 "CREATE REGULAR TABLESPACE ICMVFQ04 PAGESIZE 4K  MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML04KBP" ;
db2 "CREATE REGULAR TABLESPACE ICMSFQ04 PAGESIZE 4K  MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML04KBP" ;
db2 "CREATE REGULAR TABLESPACE CMBINV04 PAGESIZE 4K  MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML04KBP" ;
db2 "CREATE REGULAR TABLESPACE ICMLSUSRTSPACE4 PAGESIZE 4K MANAGED BY AUTOMATIC STORAGE BUFFERPOOL ICML04KBP" ;

# Disconnect to ensure a clean state ;
db2 connect reset ;
```

### 2.4 Execute the Configuration Script

Run the SQL script provided in step 2.1 to create the schemas and assign grants. We will log the output to a file for verification.

```bash
db2 -tvf SetupDb2DatabaseManually.sql -z result_final.log ;
grep "SQLCODE" result_final.log ;
```

If the log returns SUCCESS (or only successful SQL codes like 0), the database setup is complete. You can now logout from the remote server and return to your local machine.

## 3. Client-Side Configuration (OpenShift & Helm)

### 3.1 Login to OpenShift

Log in to your cluster as the administrator (or the user performing the installation).

```bash
oc login https://api.promox.europesip-lab.com:6443  -u dxadmin
```

### 3.2 Prepare Property Files

You need to prepare the `dx_dbdomain.properties` and `dx_dbtype.properties` files mapping the tables to DB2.

**Optional:** If you have the sample files provided in this repository (`custom_db2_dx_dbdomain.properties` and `custom_db2_dx_dx_dbtype.properties`), you can copy them to the required filenames:

```bash
cp custom_db2_dx_dbdomain.properties dx_dbdomain.properties ;
cp custom_db2_dx_dbtype.properties dx_dbtype.properties
```

### 3.3 Create Kubernetes Secrets

Create the generic secrets using the files prepared above. These secrets allow the WebEngine to authenticate against the new database.

```bash
oc create secret generic custom-credentials-webengine-dbtype-secret --from-file=dx_dbtype.properties ;
oc create secret generic custom-credentials-webengine-dbdomain-secret --from-file=dx_dbdomain.properties
```

### 3.4 Update Helm Values

Modify your `custom-values.yaml` to enable the database transfer configuration.
Note: Ensure that configuration.webEngine.dropDatabaseTables is set to true in your values file to allow the initial transfer.
**Optional:** A sample configuration used in this lab is available in this repository as `custom-values-sample.yaml`. If you wish to use it as a base:
```bash
cp custom-values-sample.yaml custom-values.yaml
```

---
### 3.5 Execute Helm Upgrade

Perform the Helm upgrade to instruct the WebEngine to start the database transfer.

```bash
helm upgrade dx-deployment \
  -n digital-experience \
  -f custom-values.yaml \
  ../required-assets/hcl-dx-deployment-2.42.1.tgz \
  --reuse-values 
```

Note: We use the --reuse-values flag to ensure that the currently active configuration is preserved and merged with the new changes.

You can see how the database transfer progress checking the logs of the WebEngine:
```bash
oc logs -f dx-deployment-web-engine-0 -c system-out-log
```

## 4. Post-Deployment Critical Step

> [!IMPORTANT]
> **ACTION REQUIRED IMMEDIATELY AFTER UPGRADE**
>
> Once the upgrade and transfer are complete, you must ensure that the `configuration.webEngine.dropDatabaseTables` property is reverted back to `false`.
>
> It is **STRONGLY** recommended to modify your `custom-values.yaml` and perform a configuration update immediately.
> **Failure to do so could lead to new transfers being initiated during future restarts, resulting in unexpected data loss.**
