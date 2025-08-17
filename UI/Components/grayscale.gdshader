shader_type canvas_item;

uniform float progress:hint_range(0.,1.)=0.;
const float f=.02;
void fragment(){
vec4 c=texture(TEXTURE,UV);
float g=dot(c.rgb,vec3(.299,.587,.114));
float m=smoothstep(progress-f,progress+f,1.-UV.y);
COLOR=vec4(mix(c.rgb,vec3(g),m),c.a);
}
