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

            #include "Assets/Shaders/Noise.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float3 RandomRainbow(float2 uv) {
                float chronoTime = _Time.y * _TimeScale + chrono * _ChronoScale;
                float p = noise(float3(uv * float2(scaleX, 1) * _WarpScale,
                    (chronoTime * _WarpChronoTimeScale) % 1000));
                float hue = (p + chronoTime * _RainbowChronoTimeScale) * _RainbowRepeats;
                return Rainbow(hue);
            }

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
                float3 col = Rainbow(hue);
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}