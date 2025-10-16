#!/bin/bash

# Konfigurasi
SERVER="host.docker.internal"
DB_NAME="PTXYZ_DataWarehouse"
PASSWORD="PTXYZSecure123!" # Ganti jika password di .env Anda berbeda
SCHEMA_FILE="/docker-entrypoint-initdb.d/create-schema.sql"

echo "🚀 Starting Data Warehouse initialization..."

# Tunggu SQL Server benar-benar siap
echo "⏳ Waiting for SQL Server at $SERVER..."
sleep 45

# Loop untuk mengetes koneksi
for i in {1..10}; do
    /opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "sa" -P "$PASSWORD" -Q "SELECT 1" -C -N > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ SQL Server is ready!"
        break
    else
        echo "   Attempt $i/10 - SQL Server not ready yet, waiting 10 seconds..."
        sleep 10
    fi
done

# Periksa lagi setelah loop selesai
/opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "sa" -P "$PASSWORD" -Q "SELECT 1" -C -N > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ Failed to connect to SQL Server after all attempts. Exiting."
    exit 1
fi

# Buat database
echo "📊 Creating database $DB_NAME..."
/opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "sa" -P "$PASSWORD" -C -N -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'$DB_NAME') CREATE DATABASE [$DB_NAME];"
if [ $? -ne 0 ]; then
    echo "❌ Database creation failed. Exiting."
    exit 1
fi
echo "✅ Database created or already exists."

# Jalankan skrip skema
echo "🏗️  Creating schema from $SCHEMA_FILE..."
/opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "sa" -P "$PASSWORD" -d "$DB_NAME" -C -N -i "$SCHEMA_FILE"
if [ $? -ne 0 ]; then
    echo "❌ Schema creation failed. Exiting."
    exit 1
fi
echo "✅ Schema creation completed successfully."

echo "🎉 Initialization completed successfully!"