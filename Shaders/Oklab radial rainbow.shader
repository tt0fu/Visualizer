Shader "Oklab radial rainbow" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Lightness("Lightness", Range(0, 2)) = 0.5
        _Chroma("Chroma", Range(0, 2)) = 0.5
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

    struct frag_data {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    frag_data vert(appdata vert_data) {
        frag_data frag_data;
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
            float _RainbowScale;
            float _TimeScale;
            float _ChronoScale;

            #include "Oklab rainbow.cginc"

            fixed4 frag(frag_data i) : SV_Target {
                float2 p = i.uv - float2(0.5, 0.5);
                float t = _Time.y * _TimeScale + chrono * _ChronoScale;
                float hue = (length(p) - t) * _RainbowScale;
                float3 col = rainbow(hue);
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}