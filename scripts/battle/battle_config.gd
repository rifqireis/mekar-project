class_name BattleConfig
extends RefCounted

# angka penting
const MAX_OBSERVE_REQUIRED: int = 3
const DEFAULT_HEAL_AMOUNT: int = 30
const AGITATION_ON_HIT: int = 10
const AGITATION_ON_WRONG_TALK: int = 15
const DAMAGE_SEVERITY_DIVISOR: float = 60.

# log sistem
const LOG_MISS: String = "* Serangan Donga meleset! Target tertawa tanpa terluka."
const LOG_CAPTURE_FAIL: String = "* Donga mencoba mencari celah untuk menangkap anomali... (Belum siap!)"
const LOG_OBSERVE_DONE: String = "* [INFO]: Akar masalah dipahami! Entri Tambo terbuka & AJAK BICARA (Engage) kini aktif!"
const LOG_TRUST_HALFWAY: String = "\n* [STATUS]: Agresi musuh menurun!"

# log kondisi akhir
const LOG_VICTORY_HP: String = "* Anomali berhasil dilumpuhkan secara fisik. (Jalur Tekan)"
const LOG_VICTORY_TRUST: String = "* Target berhenti menyerang. Ia merasa dipahami dan percaya padamu! (Jalur Damai)"
const LOG_VICTORY_STABILITY: String = "* Ekosistem pulih! Target tenang kembali karena habitatnya terestorasi. (Jalur Restorasi)"
const LOG_DEFEAT: String = "* Donga kehabisan energi... Investigasi Gagal!"
