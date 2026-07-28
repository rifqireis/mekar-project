# Proyek Investigasi Anomali

Game narrative-adventure sekaligus tactical RPG, dibangun pakai Godot Engine 4. Pemain jadi **Donga**, investigator yang menangani anomali ekosistem (contohnya *Rafflesia Urbanis*) lewat eksplorasi peta, observasi, negosiasi, atau kalau perlu, konfrontasi langsung.

Fokus utama proyek ini ada di arsitektur modular dan pemisahan logika dari data, jadi konten baru bisa ditambah tanpa bongkar kode inti.

---

## Fitur & Mekanisme Gameplay

- **Interaksi terdesentralisasi** — eksplorasi peta pakai `RayCast2D` yang memanggil `interact(self)` pada objek target. Tidak ada referensi player yang di-hardcode.
- **Tiga jalur kemenangan dalam battle:**
  - **Suppress** — turunkan HP anomali sampai 0 lewat minigame akurasi dan serangan fisik.
  - **Observe & Engage** — observasi target minimal 3 kali untuk buka entri Tambo, pahami akar masalahnya, lalu pilih dialog yang tepat sampai Trust mencapai 100.
  - **Adapt** — perbaiki ekosistem sekitar target (alirkan air, tanam bibit restorasi, dll) sampai Stability mencapai 100.
- **Transisi mode battle** — Action, Dialogue, dan Minigame (termasuk bullet-hell dodge saat musuh menyerang) berjalan mulus tanpa jeda aneh.
- **Persistensi data** — HP, stamina, posisi map, dan status transisi scene disimpan lewat Autoload `PlayerRepository`.

---

## Arsitektur & Desain Kode

Ada dua bagian penting yang bikin sistem battle gampang diperluas tanpa bongkar kode UI:

**`BattleConfig.gd`** — semua angka balancing dan teks log sistem terpusat di satu skrip statis (`class_name BattleConfig`), bukan tersebar di kode UI.

**`EnemyData.gd`** — tiap musuh adalah Custom Resource (`.tres`) sendiri. Statistik HP, dialog intro, koreografi serangan, semua diatur lewat Inspector atau file resource, bukan lewat kode. `battle_ui.gd` cuma baca resource yang lagi aktif.

---

## Struktur Folder

```
res://
├── assets/
│   ├── sprites/            # Aset visual karakter, musuh, UI
│   └── fonts/              # Tipografi antarmuka
├── scenes/
│   ├── map/                # Scene eksplorasi dan objek interaktif
│   ├── battle/
│   │   ├── battle_ui.tscn  # Antarmuka battle
│   │   └── minigames/      # Arena minigame (MinigameArena)
│   └── autoload/           # PlayerRepository.tscn
├── scripts/
│   ├── autoload/
│   │   └── PlayerRepository.gd
│   ├── battle/
│   │   ├── battle_ui.gd
│   │   └── BattleConfig.gd
│   └── resources/
│       └── EnemyData.gd
├── resources/
│   └── enemies/
│       └── rafflesia_urbanis.tres
└── .gitignore
```

---

## Instalasi

**Prasyarat:**
- Godot Engine 4.1 ke atas (Standard atau .NET)
- Git versi terbaru

**Langkah:**

1. Clone repo:
   ```bash
   git clone git@github.com:username-kamu/nama-repo.git
   cd nama-repo
   ```
2. Buka lewat Godot Project Manager → Import → pilih `project.godot`.
3. Cek Project Settings → Input Map, pastikan Custom Input Actions (navigasi, interaksi, kontrol minigame) sudah terdaftar.

---

## Version Control

`.gitignore` sudah dikonfigurasi khusus untuk Godot 4. Folder-folder ini jangan pernah diunggah ke repo:

- `.godot/`
- `*.godot/imported/`
- `*.godot/editor/`

Alur kerja harian:

```bash
git status
git add .
git commit -m "Refactor: Pemisahan data musuh ke Resource dan modul BattleConfig"
git push origin main
```
