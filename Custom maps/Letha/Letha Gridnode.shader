Shader "Letha Gridnode" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Lightness("Lightness", Range(0, 2)) = 0.7
        _Chroma("Chroma", Range(0, 2)) = 0.1
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

    FragData vert(appdata vertex) {
        FragData pixel;
        pixel.vertex = UnityObjectToClipPos(vertex.vertex);
        pixel.uv = vertex.uv;
        return pixel;
    }
    ENDCG

    SubShader {
        Tags {
            "RenderType" = "Opaque"
        }
        Pass {
            CGPROGRAM
            #pragma fragment frag
            Buffer<float> samples;
            uint samplesSize;
            uint samplesStart;
            float period;
            float focus;
            float centerSample;
            float scaleX;
            float bass;
            float chrono;

            StructuredBuffer<float2> dft;
            uint dftSize;
            float lowestFrequency;
            float expBins;

            #define RESOLUTION int2(120, 13)

            float _Lightness;
            float _Chroma;

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

            #include "../../Shaders/Oklab rainbow.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float4 frag(FragData pixel) :SV_Target {
                int2 coords = pixel.uv * RESOLUTION;
                int id = coords.x * RESOLUTION.y + (RESOLUTION.y - coords.y - 1);
                if (id < 130) {
                    int lightId = id / 13;
                    int channel = id % 13;
                    bool left = lightId < 5;
                    if (channel == 0 || channel == 1) {
                        // pan, pan fine
                        float x = chrono * 5 + lightId * 0.1;
                        float pan = (sin(x * UNITY_TWO_PI) + 1) / 2;
                        return channel == 0 ? pan : frac(pan * 256);
                    }
                    if (channel == 2 || channel == 3) {
                        // tilt, tilt fine
                        channel -= 2;
                        float x = chrono * 5 + lightId * 0.1;
                        float tilt = (cos(x * UNITY_TWO_PI) + 1) / 2;
                        return channel == 0 ? tilt : frac(tilt * 256);
                    }
                    if (channel == 4) {
                        // dimmer
                        return bass;
                    }
                    if (5 <= channel && channel <= 7) {
                        // red, green, blue
                        channel -= 5;
                        float3 col = Rainbow(frac(chrono * 5 + lightId * 0.1));
                        return channel == 0 ? col.r : channel == 1 ? col.g : col.b;
                    }
                    if (channel == 8) {
                        // strobe
                    }
                    if (channel == 9) {
                        // zoom
                    }
                    if (channel == 10) {
                        // GOBO
                    }
                    if (channel == 11) {
                        // GOBO spin speed
                    }
                    if (channel == 12) {
                        // mover speed
                    }
                    return 0;
                }
                if (id < 170) {
                    id -= 130;
                    int lightId = id / 5;
                    int channel = id % 5;
                    if (channel == 0) {
                        // dimmer
                        return bass;
                    }
                    if (1 <= channel && channel <= 3) {
                        // red, green, blue
                        channel -= 1;
                        float3 col = Rainbow(frac(chrono * 5 + lightId * 0.2));
                        return channel == 0 ? col.r : channel == 1 ? col.g : col.b;
                    }
                    if (channel == 4) {
                        // strobe
                    }
                    return 0;
                }
                return 0;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}