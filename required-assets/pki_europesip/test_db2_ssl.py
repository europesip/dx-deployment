import ibm_db
import sys
import os

# --- CONFIGURACIÓN ---
dsn_hostname = "db2.europesip-lab.com"
dsn_uid      = "db2inst1"
dsn_pwd      = "Passw0rd"
dsn_port     = "50001"
dsn_database = "WPSDB"
cert_path    = os.path.abspath("./europesip-ca.pem")

# --- CADENA DE CONEXIÓN ---
dsn = (
    f"DRIVER={{IBM DB2 ODBC DRIVER}};"
    f"DATABASE={dsn_database};"
    f"HOSTNAME={dsn_hostname};"
    f"PORT={dsn_port};"
    f"PROTOCOL=TCPIP;"
    f"UID={dsn_uid};"
    f"PWD={dsn_pwd};"
    f"SECURITY=SSL;"
    f"SSLServerCertificate={cert_path};"
)

try:
    print(f"Conectando por SSL a {dsn_database}...")
    conn = ibm_db.connect(dsn, "", "")
    print("✅ Conexión establecida.\n")

    # --- CONSULTA DE SCHEMAS ---
    # Consultamos la tabla de catálogo de DB2 para listar esquemas
    sql = "SELECT SCHEMANAME FROM SYSCAT.SCHEMATA ORDER BY SCHEMANAME"
    stmt = ibm_db.exec_immediate(conn, sql)
    
    print("Listado de SCHEMAS en la base de datos:")
    print("-" * 40)
    
    row = ibm_db.fetch_assoc(stmt)
    count = 0
    while row:
        print(f"  - {row['SCHEMANAME']}")
        count += 1
        row = ibm_db.fetch_assoc(stmt)
    
    print("-" * 40)
    print(f"Total: {count} esquemas encontrados.")

    ibm_db.close(conn)
    
except Exception as e:
    print("❌ ERROR:")
    print(str(e))
    sys.exit(1)
