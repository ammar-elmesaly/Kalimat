shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Add a uniform to control green intensity
uniform float green_boost: hint_range(1.0, 10.0) = 1.0;

void fragment() {
    // Sample the current fragment color
    vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);

    // Amplify the green channel
    color.g *= green_boost;

    // Ensure the green channel does not exceed 1.0
    color.g = clamp(color.g, 0.0, 1.0);

    // Output the modified color
    COLOR = color;
}
