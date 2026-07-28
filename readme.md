# Proyek Gemastik

Game narrative-adventure dan tactical RPG berbasis Godot Engine 4. Pemain berperan sebagai Donga, investigator yang menangani anomali ekosistem (contohnya Rafflesia Urbanis) melalui eksplorasi peta, observasi, negosiasi, atau konfrontasi fisik.

Proyek ini menekankan arsitektur modular dan pemisahan logika dari data, sehingga konten baru bisa ditambahkan tanpa mengubah kode inti.

## Fitur

- **Interaksi terdesentralisasi**: eksplorasi peta menggunakan `RayCast2D` yang memanggil `interact(self)` pada objek target, tanpa hardcode referensi player.
- **Tiga jalur kemenangan dalam battle**:
  - *Suppress*: menurunkan HP anomali sampai 0 lewat minigame akurasi dan serangan fisik.
  - *Observe & Engage*: observasi target minimal 3 kali untuk membuka entri Tambo, memahami akar masalahnya, lalu memilih dialog yang tepat hingga Trust mencapai 100.
  - *Adapt*: memperbaiki ekosistem sekitar target (mengalirkan air, menanam bibit restorasi, dll) hingga Stability mencapai 100.
- **Transisi mode battle**: Action, Dialogue, dan Minigame (termasuk bullet-hell dodge saat musuh menyerang) berjalan tanpa loading terpisah.
- **Persistensi data**: HP, stamina, posisi map, dan status transisi scene disimpan melalui Autoload `PlayerRepository`.

## Arsitektur

**`BattleConfig.gd`**: seluruh konstanta balancing dan teks log sistem disimpan terpusat dalam satu skrip statis (`class_name BattleConfig`), tidak tersebar di kode UI.

**`EnemyData.gd`**: setiap musuh adalah instansiasi Custom Resource (`.tres`). Statistik HP, dialog intro, koreografi serangan, dan pilihan dialog dikonfigurasi lewat Inspector atau file resource. `battle_ui.gd` hanya membaca resource yang sedang aktif.

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

## Instalasi

Prasyarat:
- Godot Engine 4.1 atau lebih baru (Standard atau .NET)
- Git versi terbaru

Langkah:

1. Clone repository:
   ```bash
   git clone git@github.com:username-kamu/nama-repo.git
   cd nama-repo
   ```
2. Buka Godot Project Manager, klik Import, lalu pilih `project.godot`.
3. Pastikan Custom Input Actions (navigasi, interaksi, kontrol minigame) sudah terdaftar di Project Settings > Input Map.

## Version Control

File `.gitignore` sudah dikonfigurasi khusus untuk Godot 4. Folder berikut tidak boleh diunggah ke repository:

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
