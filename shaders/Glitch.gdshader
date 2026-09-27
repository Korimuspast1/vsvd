shader_type canvas_item;
uniform float intensity=0.0;
void fragment(){ vec2 uv=UV; float band=floor(uv.y*24.0); uv.x+=step(0.85,fract(sin(band+TIME*10.0)*43758.5))*0.05*intensity; COLOR=texture(TEXTURE,uv); }
