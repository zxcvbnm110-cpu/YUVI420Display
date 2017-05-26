#version 330 core
in vec2 TexCoord;

uniform sampler2D SamplerY;
uniform sampler2D SamplerU;
uniform sampler2D SamplerV;

out vec4 color;

void main(void)
{
    vec3 yuv;
    vec3 rgb;
    
    yuv.x = texture(SamplerY, TexCoord).r;
    yuv.y = texture(SamplerU, TexCoord).r - 0.5;
    yuv.z = texture(SamplerV, TexCoord).r - 0.5;
    
    rgb = mat3( 1.0      ,1.0       ,      1.0,
                0      ,-0.39465,2.03211,
                1.13983,-0.58060,      0) * yuv;
    
    color = vec4(rgb,0);
}
