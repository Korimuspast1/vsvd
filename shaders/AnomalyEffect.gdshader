shader_type canvas_item;
uniform float intensity=0.0;
void fragment(){ vec2 uv=UV; uv.x += sin(uv.y*40.0+TIME*8.0)*0.01*intensity; vec4 c=texture(TEXTURE,uv); float d=distance(UV,vec2(0.5)); c.rgb*=1.0-smoothstep(0.35,0.75,d)*intensity; c.r+=0.03*intensity; c.b-=0.02*intensity; COLOR=c; }
