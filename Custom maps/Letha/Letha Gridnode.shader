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

            #define RESOLUTION uint2(120, 13)

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

            float DFTLerp(float x) {
                return DFT(lerp(Bin(30), Bin(100), x));
            }

            #include "../../Shaders/Oklab rainbow.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float3 RainbowChrono(float x) {
                return Rainbow(frac(chrono * 2 + x * 0.5));
            }

            float4 frag(FragData pixel) :SV_Target {
                uint2 coords = pixel.uv * RESOLUTION;
                uint id = coords.x * RESOLUTION.y + (RESOLUTION.y - coords.y - 1);
                if (id < 130) {
                    uint lightId = (id / 13);
                    uint channel = id % 13;
                    bool left = lightId < 5;
                    lightId %= 5;
                    if (channel == 0 || channel == 1) {
                        // pan, pan fine
                        float pan = left ? 0.4 : 1;
                        return channel == 0 ? pan : frac(pan * 256);
                    }
                    float x = float(lightId) / 4;
                    float dft = DFTLerp(x);
                    if (channel == 2 || channel == 3) {
                        // tilt, tilt fine
                        channel -= 2;
                        float tilt = dft + 0.07;
                        return channel == 0 ? tilt : frac(tilt * 256);
                    }
                    if (channel == 4) {
                        // zoom
                        return dft * 2;
                    }
                    if (channel == 5) {
                        // dimmer
                        return 1;
                    }
                    if (channel == 6) {
                        // strobe
                        return dft * 4 - 0.5;
                    }
                    if (7 <= channel && channel <= 9) {
                        // red, green, blue
                        channel -= 7;
                        float3 col = RainbowChrono(x);
                        return channel == 0 ? col.r : channel == 1 ? col.g : col.b;
                    }
                    if (channel == 10) {
                        // GOBO spin speed
                        return 0;
                    }
                    if (channel == 11) {
                        // GOBO
                        return 0;
                    }
                    if (channel == 12) {
                        // mover speed
                        return 0.5;
                    }
                    return 0;
                }
                if (id < 170) {
                    id -= 130;
                    uint lightId = id / 5;
                    uint channel = id % 5;
                    bool left = lightId < 4;
                    lightId %= 4;
                    float x = float(lightId) / 4 + 0.125;
                    float dft = DFTLerp(x);
                    if (channel == 0) {
                        // dimmer
                        return dft * 4;
                    }
                    if (1 <= channel && channel <= 3) {
                        // red, green, blue
                        channel -= 1;
                        float3 col = RainbowChrono(x);
                        return channel == 0 ? col.r : channel == 1 ? col.g : col.b;
                    }
                    if (channel == 4) {
                        // strobe
                        return dft * 4 - 0.5;
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