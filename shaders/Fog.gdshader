shader_type spatial;
uniform vec4 fog_color:source_color=vec4(0.2,0.24,0.26,1.0);
void fragment(){ ALBEDO=fog_color.rgb; ALPHA=0.35; }
