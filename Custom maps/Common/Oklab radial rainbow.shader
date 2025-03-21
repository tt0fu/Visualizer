Shader "Oklab radial rainbow" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Lightness("Lightness", Range(0, 2)) = 0.7
        _Chroma("Chroma", Range(0, 2)) = 0.1
        _RainbowScale("Rainbow scale", Range(0, 10)) = 0.5
        _TimeScale("Time scale", Range(0, 10)) = 0.5
        _ChronoScale("Chrono scale", Range(0, 10)) = 0.5
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

            float _Lightness;
            float _Chroma;
            float _RainbowScale;
            float _TimeScale;
            float _ChronoScale;

            #include "Assets/Shaders/Oklab rainbow.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float4 frag(FragData i) : SV_Target {
                float2 uv = i.uv - float2(0.5, 0.5);
                uv.x *= scaleX;
                float2 p = uv;
                float t = _Time.y * _TimeScale + chrono * _ChronoScale;
                float hue = (length(p) - t) * _RainbowScale;
                float3 col = Rainbow(hue);
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}