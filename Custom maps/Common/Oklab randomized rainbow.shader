Shader "Oklab randomized rainbow" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Mask ("Mask", 2D) = "white" {}
        _MaskCutoff("Mask cutoff", Range(0, 1)) = 0.05
        _Lightness("Lightness", Range(0, 2)) = 0.7
        _Chroma("Chroma", Range(0, 2)) = 0.1
        _RainbowRepeats("Rainbow repeats", Range(0, 10)) = 2
        _TimeScale("Time scale", Range(0, 10)) = 0.1
        _ChronoScale("Chrono scale", Range(0, 10)) = 1
        _WarpScale("Warp scale", Range(0, 20)) = 5
        _WarpChronoTimeScale("Warp chrono+time scale", Range(0, 10)) = 1
        _RainbowChronoTimeScale("Rainbow chrono+time scale", Range(0, 10)) = 1
    }
    CGINCLUDE
    #pragma vertex vert
    #include "UnityCG.cginc"

    struct appdata {
        float2 uv : TEXCOORD0;
        float4 vertex : POSITION;
    };

    struct FragData {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    FragData vert(appdata vert_data) {
        FragData frag_data;
        frag_data.vertex = UnityObjectToClipPos(vert_data.vertex);
        frag_data.uv = vert_data.uv;
        return frag_data;
    }
    ENDCG

    SubShader {
        Tags {
            "RenderType"="Opaque"
        }

        Pass {
            CGPROGRAM
            #pragma fragment frag
            float chrono;
            float scaleX;


            sampler2D _Mask;
            float _MaskCutoff;
            float _Lightness;
            float _Chroma;
            float _RainbowRepeats;
            float _TimeScale;
            float _ChronoScale;
            float _WarpScale;
            float _WarpChronoTimeScale;
            float _RainbowChronoTimeScale;


            #include "Assets/Shaders/Oklab rainbow.cginc"


            #define rand(p)  frac(sin(1e3*dot(p,float3(1,57,-13.7)))*4375.5453)

            float noise3(float3 x) {
                float3 p = floor(x), f = frac(x);

                f = f * f * (3. - 2. * f); // smoothstep

                return lerp(lerp(lerp(rand(p+float3(0,0,0)), rand(p+float3(1,0,0)), f.x), // triilinear
                                 lerp(rand(p+float3(0,1,0)), rand(p+float3(1,1,0)), f.x), f.y),
                            lerp(lerp(rand(p+float3(0,0,1)), rand(p+float3(1,0,1)), f.x),
                                lerp(rand(p+float3(0,1,1)), rand(p+float3(1,1,1)), f.x), f.y), f.z);
            }

            #define noise(x) (noise3(x)+noise3(x+11.5)) / 2.


            float4 frag(FragData i) : SV_Target {
                float mask = tex2D(_Mask, i.uv);
                if (mask < _MaskCutoff) {
                    discard;
                    return 0;
                }
                float chronoTime = _Time.y * _TimeScale + chrono * _ChronoScale;
                float p = noise(float3(i.uv * float2(scaleX, 1) * _WarpScale,
                    (chronoTime * _WarpChronoTimeScale) % 1000));
                float hue = (p + chronoTime * _RainbowChronoTimeScale) * _RainbowRepeats;
                float3 col = rainbow(hue);
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}