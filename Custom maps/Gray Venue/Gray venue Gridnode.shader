Shader "Gray venue Gridnode" {
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

            float DFTBass(float x) {
                return DFT(lerp(Bin(30), Bin(100), x));
            }

            #include "../../Shaders/Oklab rainbow.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float3 RainbowChrono(float x) {
                return Rainbow(frac(chrono * 2 + x * 0.5));
            }

            float SplitFine(float value, uint channel) {
                return channel == 0 ? value : frac(value * 256);
            }

            float SplitColor(float3 color, uint channel) {
                return channel == 0 ? color.r : channel == 1 ? color.g : color.b;
            }

            float SinTest() {
                return sin(_Time.y * UNITY_HALF_PI) * 0.5 + 0.5;
            }

            float Mover(uint lightId, uint channel) {
                lightId %= 8;
                float x = float(lightId) / 8;
                float dft = DFTBass(x);
                if (channel == 0 || channel == 1) {
                    // Pan, Pan fine
                    float pan = 0.5;
                    return SplitFine(pan, channel);
                }
                if (channel == 2 || channel == 3) {
                    // Tilt, Tilt fine
                    float tilt = 0.33 + clamp(dft, 0, 0.4);
                    return SplitFine(tilt, channel - 2);
                }
                if (channel == 4) {
                    // Zoom
                    return dft * 2;
                }
                if (channel == 5) {
                    // Dimmer
                    return 1;
                }
                if (channel == 6) {
                    // Strobe
                    return dft * 3 - 0.5;
                }
                if (7 <= channel && channel <= 9) {
                    // Red, Green, Blue
                    return SplitColor(RainbowChrono(x), channel - 7);
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
                    // Mover speed
                    return 0.5;
                }
                return 0;
            }

            float ParLight(uint lightId, uint channel) {
                lightId %= 8;
                float x = float(lightId) / 8;
                float dft = DFTBass(x);
                if (channel == 0) {
                    // dimmer
                    return dft * 4;
                }
                if (1 <= channel && channel <= 3) {
                    // red, green, blue
                    return SplitColor(RainbowChrono(x), channel - 1);
                }
                if (channel == 4) {
                    // strobe
                    return dft * 3 - 0.5;
                }
                return 0;
            }

            float Laser(uint lightId, uint channel) {
                lightId %= 8;
                float x = float(lightId) / 8;
                float dft = DFTBass(x);
                if (channel == 0) {
                    // Pan
                    return 1 - dft * 1.5;
                }
                if (channel == 1) {
                    // Tilt
                    return 0;
                }
                if (channel == 2) {
                    // Length
                    return 1; // - dft;
                }
                if (channel == 3) {
                    // Width
                    return dft * 2 - 0.6;
                }
                if (channel == 4) {
                    // Flatness
                    return 0;
                }
                if (channel == 5) {
                    // Beam Count
                    return 0;
                }
                if (channel == 6) {
                    // Spin Speed
                    return 0;
                }
                if (7 <= channel && channel <= 9) {
                    // red, green, blue
                    return SplitColor(RainbowChrono(x), channel - 7);
                }
                if (channel == 10) {
                    // Dimmer
                    return dft * 4 - 0.5;
                }
                if (channel == 11) {
                    // Beam Thickness
                    return 0;
                }
                if (channel == 12) {
                    // Pan/Tilt Speed
                    return 0;
                }
                return 0;
            }

            float4 frag(FragData pixel) :SV_Target {
                uint2 coords = pixel.uv * RESOLUTION;
                uint id = coords.x * RESOLUTION.y + (RESOLUTION.y - coords.y - 1);
                if (id < 13 * 16) {
                    return Mover(id / 13, id % 13);
                }
                if (id < 13 * 16 + 5 * 16) {
                    id -= 13 * 16;
                    return ParLight(id / 5, id % 5);
                }
                if (id < 13 * 16 + 5 * 16 + 13 * 16) {
                    id -= 13 * 16 + 5 * 16;
                    return Laser(id / 13, id % 13);
                }
                return 0;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}