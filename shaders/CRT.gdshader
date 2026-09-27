shader_type canvas_item;
uniform float scanline_strength=0.18;
uniform float noise_strength=0.02;
void fragment(){ vec2 uv=UV; vec4 c=texture(TEXTURE,uv); float scan=sin(uv.y*900.0)*scanline_strength; c.rgb-=scan; c.rgb+=fract(sin(dot(uv*TIME,vec2(12.9898,78.233)))*43758.5453)*noise_strength; COLOR=c; }
