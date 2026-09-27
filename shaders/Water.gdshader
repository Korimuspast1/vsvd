shader_type spatial;
render_mode blend_mix;
uniform vec4 water_color:source_color=vec4(0.08,0.18,0.22,0.75);
void fragment(){ ALBEDO=water_color.rgb; ALPHA=water_color.a; ROUGHNESS=0.25; }
