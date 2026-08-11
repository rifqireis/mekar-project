shader_type canvas_item;

uniform float circle_size : hint_range(0.0, 1.2) = 0.0;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    
    uv.x *= 1.777;
    
    float dist = length(uv);
    
    float alpha = 1.0 - smoothstep(circle_size - 0.01, circle_size + 0.01, dist);
    
    COLOR = vec4(255, 255, 255, alpha);
}