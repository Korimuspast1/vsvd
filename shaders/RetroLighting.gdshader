shader_type spatial;
render_mode diffuse_lambert,specular_blinn;
uniform float desaturation=0.25;
void fragment(){ vec3 gray=vec3(dot(ALBEDO,vec3(0.299,0.587,0.114))); ALBEDO=mix(ALBEDO,gray,desaturation); ROUGHNESS=0.45; SPECULAR=0.7; }
