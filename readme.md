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

Struktur berbasis fitur/domain (feature-first): setiap sistem & lokasi berisi
scene + script-nya sendiri. Nama folder mengikuti konteks game (Bab, lokasi,
karakter) dari proposal.

```
res://
├── assets/                  # Aset biner (nama file dipertahankan, di-sync via R2)
├── data/                    # Resource yang di-set lewat Inspector
│   ├── animations/          # *.res (AnimationLibrary / Animation)
│   └── enemies/             # EnemyData *.tres (arnoldios, meranti, ular_enggano)
├── game/
│   ├── autoload/            # Singleton global (player_repository, scene_transition, pause_menu)
│   ├── player/              # Kontrol pemain (Donga)
│   ├── systems/             # Mekanik inti
│   │   ├── resolve/         # Resolve System — battle non-kekerasan
│   │   ├── enemy/           # EnemyData.gd (HP/Trust/Stability/Agitation)
│   │   └── minigames/       # attack, dodge (pola serangan musuh)
│   ├── world/               # Lokasi & konten level
│   │   ├── common/          # Node dunia reusable (camera, door, encounter, npc)
│   │   ├── characters/      # NPC/makhluk (chicha, orey, ghearld, meranti, ular_enggano)
│   │   ├── interactables/   # Objek bisa diinteraksi (arnoldios, wood_obstacle)
│   │   ├── bukit_kaba/      # Bab 1 — Hutan Bukit Kaba (tutorial + boss)
│   │   ├── rumah_donga/     # Hub naratif (Rumah Bubungan Lima)
│   │   └── suprapto/        # Hub kota (Distrik Suprapto)
│   ├── narrative/           # Cerita
│   │   ├── dialogue/        # Balloon, dialogue box, lines/*.dialogue
│   │   └── cutscenes/       # Cutscene (introduction)
│   └── ui/                  # menus (main_menu, about_dev), hud (tutorial_ui)
├── addons/                  # Plugin eksternal (dialogue_manager)
└── project.godot
```

> Konvensi penamaan: `snake_case`, ASCII, tanpa spasi/tanda kurung, scene & script
> satu nama batang. Ejaan karakter/lokasi mengikuti proposal (mis. `chicha`,
> `suprapto`, `arnoldios`, `bukit_kaba`).

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
