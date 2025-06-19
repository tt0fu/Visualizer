#define rand(p)  frac(sin(1e3*dot(p,float3(1,57,-13.7)))*4375.5453)

float noise3(float3 x) {
    float3 p = floor(x), f = frac(x);

    f = f * f * (3. - 2. * f); // smoothstep

    return lerp(lerp(lerp(rand(p+float3(0,0,0)), rand(p+float3(1,0,0)), f.x), // triilinear
                     lerp(rand(p+float3(0,1,0)), rand(p+float3(1,1,0)), f.x), f.y),
                lerp(lerp(rand(p+float3(0,0,1)), rand(p+float3(1,0,1)), f.x),
                    lerp(rand(p+float3(0,1,1)), rand(p+float3(1,1,1)), f.x), f.y), f.z);
}

#define noise(x) (noise3(sin(x))+noise3(cos(1.618 * x)+11.5)) / 2.