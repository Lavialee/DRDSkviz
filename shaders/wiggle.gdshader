shader_type canvas_item;
// --- Uniforms --- //
uniform vec2 amplitude = vec2(0.2, 0.2); // Reduced amplitude for smaller waves
uniform vec2 speed = vec2(1.0, 1.0);
uniform vec2 frequency = vec2(10.0, 10.0); // Added frequency parameter
uniform float alpha = 1.0; // Overall transparency (0.0 to 1.0)

// --- Functions --- //
void fragment() {
    vec2 pos = mod((UV - amplitude * cos(TIME + vec2(UV.y, UV.x) * frequency * speed)) / TEXTURE_PIXEL_SIZE,
            1.0 / TEXTURE_PIXEL_SIZE) * TEXTURE_PIXEL_SIZE;
    
    // Get the distorted texture color
    vec4 color = texture(TEXTURE, pos);
    
    // Apply overall transparency by modifying the alpha channel
    COLOR = vec4(color.rgb, color.a * alpha);
}