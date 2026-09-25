# Proyek Gemastik

Game narrative-adventure dan tactical RPG berbasis Godot Engine. Pemain berperan sebagai Donga, investigator yang menangani "sengketa" ekosistem melalui eksplorasi peta, observasi, negosiasi, atau konfrontasi.

## Struktur Folder

```
res://
├── assets/                  
├── data/                    
│   ├── animations/          
│   └── enemies/             
├── game/
│   ├── autoload/            
│   ├── player/              # donga
│   ├── systems/             
│   │   ├── resolve/         
│   │   ├── enemy/           
│   │   └── minigames/       # attack, dodge
│   ├── world/               # lokasi level
│   │   ├── common/          # semua yg reusable
│   │   ├── characters/      
│   │   ├── interactables/   
│   │   ├── bukit_kaba/      # bab 1
│   │   ├── rumah_donga/     
│   │   └── suprapto/        
│   ├── narrative/           # building plot/cerita
│   │   ├── dialogue/        
│   │   └── cutscenes/       
│   └── ui/                  
├── addons/                  
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


