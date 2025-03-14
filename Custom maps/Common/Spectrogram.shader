﻿Shader "Spectrogram" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _StartFreq("Starting frequency to display", Float) = 0
        _EndFreq("Ending frequency to display", Float) = 44000
        _Scale("Scale of the waves", Range(0, 10)) = 3
        _Cutoff("Cutoff of the waves", Range(0, 0.1)) = 0.01
        [ToggleUI]_Flip("Flip x axis", Int) = 0
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
        //        Tags {
        //            "Queue" = "Transparent"
        //            "IgnoreProjector" = "True"
        //            "RenderType" = "Transparent"
        //        }
        //        ZWrite Off
        //        Blend SrcAlpha OneMinusSrcAlpha
        //        LOD 100
        Tags {
            "RenderType" = "Opaque"
        }

        Pass {
            CGPROGRAM
            #pragma fragment frag
            StructuredBuffer<float2> dft;
            uint dftSize;
            float lowestFrequency;
            float expBins;

            float _StartFreq;
            float _EndFreq;
            float _Scale;
            float _Cutoff;
            bool _Flip;

            float RawDFT(int bin) {
                if (bin < 0) {
                    bin = 0;
                }
                if (bin > dftSize - 1) {
                    bin = dftSize - 1;
                }
                return length(dft.Load(bin));
            }

            float DFT(float bin) {
                return lerp(RawDFT(floor(bin)), RawDFT(ceil(bin)), frac(bin));
            }


            float Bin(float frequency) {
                return clamp(expBins * log2(frequency / lowestFrequency), 0, dftSize);
            }

            float4 frag(FragData i) : SV_Target {
                float startBin = Bin(_StartFreq);
                float endBin = Bin(_EndFreq);
                float bin = lerp(startBin, endBin, _Flip ? 1 - i.uv.x : i.uv.x);

                float height = max(DFT(bin) - _Cutoff, 0) *
                    _Scale;
                if (i.uv.y < height) {
                    return 1;
                }
                discard;
                return 0;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}