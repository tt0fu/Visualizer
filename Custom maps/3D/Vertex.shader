Shader "Vertex" {
    Properties {}
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            Texture2D<float> samples;

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 orig_vertex : TEXCOORD0;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.orig_vertex = v.vertex.xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                return i.orig_vertex.z;
            }
            ENDCG
        }
    }
}