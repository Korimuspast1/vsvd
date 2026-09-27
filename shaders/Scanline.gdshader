shader_type canvas_item;
uniform float opacity=0.2;
void fragment(){ vec4 c=texture(TEXTURE,UV); float line=step(0.5,fract(UV.y*480.0)); COLOR=vec4(c.rgb*(1.0-line*opacity),c.a); }
