Shader "Waveform" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Width ("Width", Range(1, 200)) = 20
        _Height ("Height", Range(0, 10)) = 1.0
        [ToggleUI] _Debug ("Debug mode", Int) = 0
        [ToggleUI] _DisableStabilization ("Disable stabilization", Int) = 0
        [ToggleUI] _Rainbow ("Rainbow", Int) = 0
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
            float chrono;

            float _Width;
            float _Height;
            bool _Debug;
            bool _DisableStabilization;
            bool _Rainbow;
            float _Lightness;
            float _Chroma;
            float _RainbowRepeats;
            float _TimeScale;
            float _ChronoScale;
            float _WarpScale;
            float _WarpChronoTimeScale;
            float _RainbowChronoTimeScale;

            float RawSample(int sample_index) {
                if (!_DisableStabilization) {
                    sample_index += centerSample - samplesSize * focus;
                }
                if (sample_index < 0) {
                    sample_index += period * ceil((0 - sample_index) / period);
                }
                if (sample_index >= samplesSize) {
                    sample_index -= period * ceil((sample_index - samplesSize + 1) / period);
                }

                return samples.Load((sample_index + samplesStart) % samplesSize) * _Height;
            }

            float Sample(float sample_index) {
                return lerp(RawSample(floor(sample_index)), RawSample(ceil(sample_index)), frac(sample_index));
            }

            float Fade(const float dist) {
                const float x = clamp(dist, 0, 1);
                return 1 - sqrt(1 - (x - 1) * (x - 1));
            }

            float PseudoCross(float2 a, float2 b) {
                return a.x * b.y - b.x * a.y;
            }

            float PointToSegment(float2 p1, float2 p2, float2 a) {
                p1.x *= scaleX;
                p2.x *= scaleX;
                a.x *= scaleX;
                float2 ap1 = p1 - a;
                float2 ap2 = p2 - a;
                float2 p1p2 = p2 - p1;
                if (dot(p1p2, -ap1) < 0 || dot(-p1p2, -ap2) < 0) {
                    return min(length(ap1), length(ap2));
                }
                if (length(p1p2) < 1e-12) {
                    return length(ap1);
                }
                return abs(PseudoCross(ap1, ap2)) / length(p1p2);
            }

            float2 UVPoint(float sampleIndex) {
                return float2(sampleIndex / samplesSize, Sample(sampleIndex) / 2 + 0.5);
            }

            float WaveDistance(const float2 uv) {
                float sampleIndex = uv.x * samplesSize;
                const int startIndex = floor(sampleIndex - _Width);
                const int endIndex = ceil(sampleIndex + _Width);
                float mn = 10;
                float2 last = UVPoint(startIndex);
                for (int index = startIndex + 1; index < endIndex; index++) {
                    const float2 cur = UVPoint(index);
                    mn = min(mn, PointToSegment(cur, last, uv));
                    last = cur;
                }
                return mn;
            }

            float3 DebugBarColor(float sample_index, float target, float3 color) {
                return color * Fade(abs(sample_index - target) * scaleX / _Width);
            }

            #define rand(p)  frac(sin(1e3*dot(p,float3(1,57,-13.7)))*4375.5453)

            float noise3(float3 x) {
                float3 p = floor(x), f = frac(x);

                f = f * f * (3. - 2. * f); // smoothstep

                return lerp(lerp(lerp(rand(p+float3(0,0,0)), rand(p+float3(1,0,0)), f.x), // triilinear
                                 lerp(rand(p+float3(0,1,0)), rand(p+float3(1,1,0)), f.x), f.y),
                            lerp(lerp(rand(p+float3(0,0,1)), rand(p+float3(1,0,1)), f.x),
                                lerp(rand(p+float3(0,1,1)), rand(p+float3(1,1,1)), f.x), f.y), f.z);
            }

            #define noise(x) (noise3(x)+noise3(x+11.5)) / 2.

            #include "Oklab rainbow.cginc"

            float4 frag(FragData pixel) :SV_Target {
                float3 baseCol = float3(1, 1, 1);
                if (_Rainbow) {
                    float chronoTime = _Time.y * _TimeScale + chrono * _ChronoScale;
                    float p = noise(float3(pixel.uv * float2(scaleX, 1) * _WarpScale,
                                           (chronoTime * _WarpChronoTimeScale) % 1000));
                    float hue = (p + chronoTime * _RainbowChronoTimeScale) * _RainbowRepeats;
                    baseCol = rainbow(hue);
                }
                float3 col = baseCol * Fade(WaveDistance(pixel.uv) * samplesSize / _Width);
                if (_Debug) {
                    float sampleIndex = pixel.uv.x * samplesSize;
                    if (!_DisableStabilization) {
                        sampleIndex += centerSample - samplesSize * focus;
                    }
                    col += DebugBarColor(sampleIndex, centerSample, float3(1, 0, 0));
                    col += DebugBarColor(sampleIndex, centerSample - period / 2, float3(0, 1, 0));
                    col += DebugBarColor(sampleIndex, centerSample + period / 2, float3(0, 1, 0));
                }
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}