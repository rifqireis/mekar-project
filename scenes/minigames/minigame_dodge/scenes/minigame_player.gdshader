shader_type canvas_item;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	// Ubah warna RGB menjadi putih (1.0, 1.0, 1.0), tetap pakai Alpha/transparansi asli
	COLOR = vec4(1.0, 1.0, 1.0, tex_color.a);
}