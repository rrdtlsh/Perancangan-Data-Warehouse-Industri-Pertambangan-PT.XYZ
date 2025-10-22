
# 🧭 PT XYZ Data Warehouse – RUNBOOK


**Tujuan:**  
Panduan langkah demi langkah untuk menjalankan proyek *Perancangan Data Warehouse Industri Pertambangan PT XYZ* menggunakan **Docker**, **Airflow**, dan **SQL Server**.

## 👥 Tim Pengembang

| Nama | NIM | Role | Jobdesk |
|------|-----|------|---------|
| **Raudatul Sholehah** | 2310817220002 | Ketua | Koordinasi tim dan penentuan arah proyek, Implementasi Replikasi, Menjalankan Data Warehouse|
| **M. Adi Syahputra** | 2210817210017 | Anggota | Desain OLTP Source Data, Scheduling beserta alasannya |
| **Maulidasari** | 2210817120011 | Anggota | Desain arsitektur end-to-end Data Warehouse, ETL Diagram |
| **Alysa Armelia** | 2310817120009 | Anggota | Desain Dimension Modelling atau 3NF Data Warehouse, Dokumentasi (RUNBOOK.md) |
| **Zahra Nabila** | 2310817320007 | Anggota | Insight yang didapat, Pembuatan PPT |
| **GT. Muhammad Naufal Razin** | 2210817210002 | Anggota | Diskusi perbandingan dengan arsitektur berlawanan |

---

## ⚙️ Fase 0 – Persiapan Awal & Kolaborasi Tim

### Langkah 1 – Fork Repository
1. Akses repo utama:  
   [https://github.com/rrdtlsh/Perancangan-Data-Warehouse-Industri-Pertambangan-PT.XYZ](https://github.com/rrdtlsh/Perancangan-Data-Warehouse-Industri-Pertambangan-PT.XYZ)
2. Klik **Fork → Create fork** untuk membuat salinan di akun GitHub pribadi.

### Langkah 2 – Tambahkan Kolaborator
1. Buka repo hasil fork → **Settings → Collaborators and teams**.  
2. Tambahkan username GitHub tim dan beri akses **Write**.

### Langkah 3 – Clone Repository ke Komputer
```bash
git clone https://github.com/<username>/Perancangan-Data-Warehouse-Industri-Pertambangan-PT.XYZ.git
cd Perancangan-Data-Warehouse-Industri-Pertambangan-PT.XYZ
```

### Langkah 4 – Instalasi Awal
1. Install **Docker Desktop**  
2. Install **WSL (Ubuntu)**  
   Jalankan perintah berikut di PowerShell:
   ```bash
   wsl --update
   ```
3. Pastikan Docker aktif (ikon 🐳 muncul di taskbar).  
4. Install **DBeaver** untuk koneksi ke database.

---

## 🚀 Fase 1 – Menyiapkan Infrastruktur

### Langkah 5 – Buat File Environment
```bash
copy .env.example .env
```

### Langkah 6 – Jalankan Docker Compose
```bash
docker compose up -d
```

### Langkah 7 – Verifikasi Layanan
```bash
docker compose ps
```
Pastikan semua service memiliki status `running` atau `healthy`.

---

## 🧠 Fase 2 – Menjalankan ETL

### Langkah 8 – Jalankan ETL
```bash
python -m pip install -r requirements.txt
python dags/standalone_etl.py
# atau
docker exec ptxyz_airflow_worker python /opt/airflow/dags/standalone_etl.py
```

### Langkah 9 – Menyalin Dataset ke Container
```bash
docker exec ptxyz_airflow_worker mkdir -p /opt/airflow/data/raw/Dataset
docker cp ./data/. ptxyz_airflow_worker:/opt/airflow/data/raw/Dataset/
```

---

## 🧩 Fase 3 – Penambahan Tabel Fakta Baru (Maintenance)

### Langkah 10 – Tambahkan Dataset Baru
Buat file baru di:  
`data/raw/Dataset/dataset_maintenance.csv`

Contoh isi file:
```csv
maintenance_id,date,equipment_name,site_name,maintenance_cost,downtime_duration_hours
1,2025-05-20,Excavator EX-001,Site Batu B,2500.00,8
2,2025-05-23,Dump Truck DT-003,Area Tambang C,1200.50,5
```

### Langkah 11 – Tambahkan Skema Database
```sql
CREATE TABLE fact.FactMaintenance (
    maintenance_key INT IDENTITY(1,1) PRIMARY KEY,
    time_key INT FOREIGN KEY REFERENCES dim.DimTime(time_key),
    equipment_key INT FOREIGN KEY REFERENCES dim.DimEquipment(equipment_key),
    site_key INT FOREIGN KEY REFERENCES dim.DimSite(site_key),
    maintenance_cost DECIMAL(18, 2),
    downtime_duration_hours INT
);
```

### Langkah 12 – Tambahkan ke ETL Script
```python
maintenance_df = pd.read_csv('data/raw/Dataset/dataset_maintenance.csv')
for _, row in maintenance_df.iterrows():
    cursor.execute(
        "INSERT INTO staging.Maintenance (maintenance_id, date, equipment_name, site_name, maintenance_cost, downtime_duration_hours) VALUES (?, ?, ?, ?, ?, ?)",
        tuple(row)
    )
```

---

## 📊 Fase 4 – Verifikasi & Visualisasi

### Langkah 13 – Verifikasi Database (via DBeaver)
- **Server:** localhost  
- **Port:** 1433  
- **Database:** PTXYZ_DataWarehouse  
- **User:** sa  
- **Password:** sesuai `.env`  
- **trustServerCertificate:** true

### Langkah 14 – Akses Layanan BI

| Layanan | URL |
|----------|-----|
| Airflow | http://localhost:8080 |
| Grafana | http://localhost:3000 |
| Superset | http://localhost:8088 |
| Metabase | http://localhost:3001 |
| Jupyter | http://localhost:8888 |

### Langkah 15 – Tambahkan Data Source di Grafana
- **Host:** sqlserver:1433  
- **Database:** PTXYZ_DataWarehouse  
- **User:** sa  
- **Password:** dari `.env`  
- **Encryption:** disable

### Langkah 16 – Buat Dashboard BI
```sql
SELECT dm.material_name, SUM(fp.produced_volume) AS total_produksi
FROM fact.FactProduction fp
JOIN dim.DimMaterial dm ON fp.material_key = dm.material_key
GROUP BY dm.material_name
ORDER BY total_produksi DESC;
```

---

## 🧪 Fase 5 – Validasi

### Langkah 17 – Jalankan Validasi SQL
```bash
docker cp ./tests/validate.sql ptxyz_sqlserver:/tmp/validate.sql
docker exec ptxyz_sqlserver /opt/mssql-tools18/bin/sqlcmd ^
  -S localhost -U sa -P "PTXYZSecure123!" ^
  -d PTXYZ_DataWarehouse -i /tmp/validate.sql
```

**Output yang diharapkan:** Semua test harus menunjukkan `SUCCESS`.

---

## ✅ Selesai

Proyek siap digunakan dan tervalidasi.  
Pastikan semua container aktif dan dashboard menampilkan data sesuai proses ETL.
