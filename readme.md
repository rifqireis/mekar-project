# Proyek Gemastik

Game narrative-adventure dan tactical RPG berbasis Godot Engine. Pemain berperan sebagai Donga, investigator yang menangani "sengketa" ekosistem melalui eksplorasi peta, observasi, negosiasi, atau konfrontasi.

## Struktur Folder

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


## Instalasi

Prasyarat:
- Godot Engine 4.1 atau lebih baru (Standard atau .NET)
- Git versi terbaru

Langkah:

1. Clone repository:
   ```bash
   git clone https://github.com/rifqireis/mekar-project.git
   ```
2. Buka Godot, klik Import, lalu pilih `project.godot` / direktori folder.


