Shader "Oklab linear rainbow" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Mask ("Mask", 2D) = "white" {}
        _MaskCutoff("Mask cutoff", Range(0, 1)) = 0.05
        _Lightness("Lightness", Range(0, 2)) = 0.7
        _Chroma("Chroma", Range(0, 2)) = 0.1
        _RainbowRepeats("Rainbow repeats", Range(0, 10)) = 0.5
        _TimeScale("Time scale", Range(0, 10)) = 0.5
        _ChronoScale("Chrono scale", Range(0, 10)) = 0.5
        _Direction("Direction", Range(0, 1)) = 0
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

            float _Lightness;
            float _Chroma;
            float _RainbowRepeats;
            float _TimeScale;
            float _ChronoScale;
            float _Direction;
            float _MaskCutoff;
            sampler2D _Mask;

            #include "Assets/Shaders/Oklab rainbow.cginc"

            float4 frag(FragData i) : SV_Target {
                float mask = tex2D(_Mask, i.uv);
                if (mask < _MaskCutoff) {
                    discard;
                    return 0;
                }
                float2 dir = float2(cos(_Direction * UNITY_TWO_PI), sin(_Direction * UNITY_TWO_PI));
                float p = dot(i.uv, dir);
                float t = _Time.y * _TimeScale + chrono * _ChronoScale;
                float hue = (p - t) * _RainbowRepeats;
                float3 col = rainbow(hue);
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}