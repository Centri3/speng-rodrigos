#auto_version
#auto_defines

//uniform vec3      Color;
//uniform vec4      Bright; // (Gamma, Brightness, RayBrightness, SpotBrightness)
//uniform vec4      Shape;  // (RayDensity, RayCurvature, Scale, SinFreq)
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

float hash(float n)
{
    return fract(sin(n) * 43758.5453);
}

float noise(in vec2 x)
{
	vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float  n = p.x + p.y * 57.0;
    return mix(mix(hash(n),        hash(n +  1.0), f.x),
               mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

const mat2 m2 = mat2(1.60,  1.20, -1.20, 1.60);

float fbm(in vec2 p)
{	
	float z = 0.5;
	float rezult = 0.0;
	for (int i = 1; i < 6; i++)
	{
		rezult += (sin(noise(p) * Shape.w) * 0.5 + 0.5) * z;
		z *= 0.5;
		p *= m2;
	}
	return rezult;
}

void main(void)
{
    vec2 uv0 = TexCoord * 2.0 - 1.0;
    vec2 uv  = uv0 * Shape.y * 0.05;
	vec2 uvn = normalize(uv);

    float r0 = sqrt(dot(uv0, uv0));
    float r  = sqrt(dot(uv,  uv));
    float x = dot(uvn, vec2(0.5, 0.0)) - EyePos.w;
    float y = dot(uvn, vec2(0.0, 0.5)) - EyePos.w;

    float val;
    val = fbm(Shape.z * vec2(r + y * Shape.x, r + x * Shape.x - y));
    val = smoothstep(Bright.x, Bright.x + Bright.z, val);
    val = sqrt(val);

	vec3 color = vec3(val);// / max(Color, 0.2);
    color = mix(1.0 - color, vec3(1.0), Bright.w - 2000.0 * r / (Shape.y * Bright.y));

    vec3  ray  = PixPos + EyePos.xyz;
    float dist = length(ray);
    float fade = clamp(dist - 0.05, 0.0, 1.0) * clamp(1.0 - r0, 0.0, 1.0) *
                 clamp(abs(ray.z / dist) - 0.1, 0.0, 1.0);

	uv *= m2;

    OutColor.rgb = fade * max(color, 0.0);

    // gamma correction
    OutColor.rgb = pow(OutColor.rgb, vec3(2.2)) * Color;

	OutColor.a = 0.0;
}

#endif

