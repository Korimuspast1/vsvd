shader_type canvas_item;
uniform float distortion=0.25;
void fragment(){ vec2 uv=UV; uv.x+=sin(uv.y*60.0+TIME*12.0)*0.006*distortion; vec4 c=texture(TEXTURE,uv); c.g=texture(TEXTURE,uv+vec2(0.002*distortion,0)).g; COLOR=c; }
