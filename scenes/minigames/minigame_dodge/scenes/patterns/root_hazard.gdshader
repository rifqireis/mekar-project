shader_type canvas_item;

// 0.0 = Hilang total di bawah
// 1.0 = Tumbuh penuh sampai ke ujung atas
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Seberapa halus gradasi fade pada ujung akar yang sedang tumbuh
uniform float fade_softness : hint_range(0.001, 0.2) = 0.05;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Di Godot, UV.y bernilai 0.0 (paling atas) dan 1.0 (paling bawah).
    // Batas potong bergeser dari 1.0 (bawah) menuju 0.0 (atas).
    float cutoff = 1.0 - progress;
    
    // Masking transparan: bagian di atas cutoff akan di-fade/disembunyikan
    float reveal = smoothstep(cutoff, cutoff + fade_softness, UV.y);
    
    COLOR = vec4(tex_color.rgb, tex_color.a * reveal);
}