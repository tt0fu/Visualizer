Shader "Spectrogram" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _BinStart("Starting DFT bin to display", Range(0, 512)) = 0
        _BinEnd("Ending DFT bin to display", Range(0, 512)) = 110
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
            Buffer<float> dft;
            uint dft_size;

            float get_raw_dft(int bin) {
                if (bin < 0) {
                    bin = 0;
                }
                if (bin > dft_size - 1) {
                    bin = dft_size - 1;
                }
                return dft.Load(bin);
            }

            float get_dft(float bin) {
                float sample_left = get_raw_dft(floor(bin));
                float sample_right = get_raw_dft(ceil(bin));
                return lerp(sample_left, sample_right, frac(bin));
            }

            float _BinStart;
            float _BinEnd;
            float _Scale;
            float _Cutoff;
            bool _Flip;

            fixed4 frag(frag_data i) : SV_Target {
                float height = max(get_dft(lerp(_BinStart, _BinEnd, _Flip ? 1 - i.uv.x : i.uv.x)) - _Cutoff, 0) *
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