# Dashboard monitoring proses editorial jurnal OJS

**Buka:** `Monitoring_Dashboard.html` (klik dua kali; jalan di browser, tanpa internet, satu berkas mandiri).

## Isi
| Tab | Fungsi |
|---|---|
| Ringkasan | Angka utama, persen terbit dalam target, median lama proses, status naskah |
| Lama proses | Sebaran lama proses per tahun terbit dan per edisi, median tiap tahap |
| Naskah berjalan | Daftar naskah yang belum selesai, umur, tahap, hari sejak keputusan terakhir, ekspor CSV |
| Review dan penolakan | Penugasan reviewer yang tidak direspons, persen dan tahap penolakan |
| Beban editor | Keputusan per akun (disamarkan), median ke revisi pertama |
| Kualitas data | Kelengkapan per tahun dan arti tanda kualitas |
| Data dan pembaruan | Informasi data, daftar semua naskah, ekspor CSV |

Filter di atas: rentang tahun naskah masuk, **target lama proses (default 180 hari = 6 bulan)**, acuan umur naskah berjalan (tanggal data atau hari ini), dan kotak untuk menyertakan item front/back matter.

## Memperbarui data
Tidak ada yang ditulis ke OJS (hanya membaca).

1. **Lewat skrip (mengambil data terbaru dari OJS).** Di PowerShell, folder `dashboard`:
   ```
   $env:OJS_BASE_URL = "<alamat API OJS, berakhiran /api/v1>"
   $env:OJS_API_KEY = "<API key OJS>"
   python refresh_dashboard.py --journal-name "Nama Jurnal"
   ```
   Hanya naskah yang berubah di OJS yang diambil ulang (sisanya dari cache `raw/`). Skrip menjalankan: ekstraksi, perhitungan tahap, pembersihan, pemetaan edisi, lalu membuat ulang HTML dan `dashboard_data.json`.
2. **Memuat data di halaman.** Klik **Muat data baru**, pilih `dashboard_data.json`. Data diganti sementara (kembali ke data bawaan bila halaman dimuat ulang). **Unduh data (JSON)** menyimpan data yang sedang tampil.
3. **Tanpa akses OJS:** `python refresh_dashboard.py --offline` membangun ulang dari tabel yang sudah ada.

Opsi tambahan (diteruskan ke `build_dashboard.py`): `--target 180`, `--no-titles` (tanpa judul naskah), `--with-names` (nama akun editor, bukan kode E01...), `--as-of YYYY-MM-DD`. Gunakan `--full` untuk mengabaikan cache.

## Versi untuk dewan editor (aman dibagikan)
```
python build_dashboard.py --public --hide-editors
```
Hasilnya di folder `public/` (`index.html` dan `dashboard_data.json`): **tanpa judul naskah, tanpa nama atau kode editor**, dan tab Beban editor disembunyikan. Hanya folder `public/` yang boleh diunggah atau dibagikan. Tanpa `--hide-editors`, kode editor (E01 dan seterusnya) tetap ada. Versi lengkap (`Monitoring_Dashboard.html`) memuat judul naskah yang belum terbit, jadi simpan di komputer sendiri.

`python refresh_dashboard.py --public --hide-editors` memperbarui data dari OJS lalu langsung membuat versi dewan editor.

## Aturan yang dipakai
- **Lama proses** = tanggal naskah masuk sampai tanggal terbit. Dihitung hanya untuk artikel terbit yang punya keputusan *dikirim ke produksi* dan tanggal terbit (populasi yang sama dengan deck).
- **Front-matter dan Back-matter** dicatat OJS sebagai naskah tetapi bukan artikel (72 item). Item ini ditandai dan dikeluarkan dari semua hitungan, kecuali kotak "sertakan" dicentang.
- Keputusan berkode 1 dan 19 (tanpa label) dan *Decline* pada artikel terbit tidak ditafsirkan dan tidak dipakai.
- Akun editor disamarkan (E01 dan seterusnya). Halaman Beban editor bukan penilaian kinerja individu.
- Data penugasan reviewer hanya ada untuk sebagian naskah, dan statusnya kondisi saat ini.

## Berkas
`build_dashboard.py` (membuat data dan HTML), `dashboard_template.html` (tampilan dan logika), `refresh_dashboard.py` (alur pembaruan lengkap), `dashboard_data.json` (data).
