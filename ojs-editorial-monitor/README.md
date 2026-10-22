# OJS editorial monitor

**In English.** Python tooling that reads the editorial workflow of an Open Journal Systems (OJS) journal through its read-only REST API, cleans it into per-submission tables, measures how long each stage takes, and builds a self-contained interactive monitoring dashboard (one HTML file). No journal data is included in this repository; you supply your own OJS API address and key through environment variables. The documentation below is in Indonesian.

Mengekstrak alur editorial sebuah jurnal OJS (hanya membaca lewat REST API), membersihkan datanya, menghitung lama tiap tahap,
dan membuat dashboard monitoring interaktif (satu berkas HTML mandiri).

## Prasyarat
Python 3.9 atau lebih baru dan paket di `requirements.txt`. Anda perlu API key OJS dan alamat API jurnal.

## Pemakaian
```
pip install -r requirements.txt
set OJS_BASE_URL=<alamat API OJS, berakhiran /api/v1>
set OJS_API_KEY=<API key OJS>
python dashboard/refresh_dashboard.py --journal-name "Nama Jurnal"
```
Hasilnya: `dashboard/Monitoring_Dashboard.html`. Lihat `dashboard/README.md` untuk opsi (versi untuk dewan editor tanpa judul naskah, pembaruan bertahap, mode offline).

## Struktur
- `ojs_extract_workflow.py`, `extract_issues.py`: pengambilan data dari OJS (hanya membaca, dengan cache lokal).
- `build_steps.py`, `wrangle.py`: pembersihan dan tabel per naskah.
- `analysis.py`, `slow_report.py`: analisis tambahan.
- `dashboard/`: pembuat dashboard.

## Data pribadi
Folder `raw/`, `out/`, `clean/`, `analysis/` dan keluaran dashboard memuat data naskah, reviewer, dan editor. Semuanya ada di `.gitignore` dan tidak boleh masuk git.
API key hanya dibaca dari variabel lingkungan, tidak pernah ditulis di berkas.
