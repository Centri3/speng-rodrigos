#auto_version
#auto_defines

uniform sampler2D Tex1;
uniform sampler2D Tex2;
//uniform vec3      Color;
//uniform vec4      EyePos; // (eye pos, animation time)
//uniform mat4x4    Mvp;
#uniform_block

#ifdef _VERTEX_

layout(location = 0) in  vec4  VertexPos;
layout(location = 1) in  vec4  VertexTexCoord;
                     out vec2  TexCoord;
                     out vec3  PixPos;

void main()
{
    gl_Position = Mvp * VertexPos;
    TexCoord = VertexTexCoord.xy;
    PixPos = VertexPos.xyz;
}

#else

                     in  vec2  TexCoord;
                     in  vec3  PixPos;
layout(location = 0) out vec4  OutColor;

void main()
{
    vec3  color = mix(texture(Tex1, TexCoord).rgb, texture(Tex2, TexCoord).rgb, EyePos.w);

    vec3  ray  = PixPos + EyePos.xyz;
    float dist = length(ray);
    float fade = clamp(dist - 0.05, 0.0, 1.0) *
                 clamp(abs(ray.z / dist) - 0.1, 0.0, 1.0);

    OutColor.rgb = fade * (Color * color);

    // gamma correction
    OutColor.rgb = pow(OutColor.rgb, vec3(2.2));

    OutColor.a = 0.0;
}

#endif
