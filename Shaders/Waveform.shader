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
        [ToggleUI] _FlipX ("Flip X", Int) = 0
        [ToggleUI] _FlipY ("Flip Y", Int) = 0
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
            bool _FlipX;
            bool _FlipY;

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

            #include "Oklab rainbow.cginc"

            #include "Noise.cginc"

            float3 Rainbow(float hue) {
                return lch2rgb(float3(_Lightness, _Chroma, hue));
            }

            float3 RandomRainbow(float2 uv) {
                float chronoTime = _Time.y * _TimeScale + chrono * _ChronoScale;
                float p = noise(float3(uv * float2(scaleX, 1) * _WarpScale,
                    (chronoTime * _WarpChronoTimeScale) % 1000));
                float hue = (p + chronoTime * _RainbowChronoTimeScale) * _RainbowRepeats;
                return Rainbow(hue);
            }

            float4 frag(FragData pixel) :SV_Target {
                float2 uv = pixel.uv * float2(1 - 2 * _FlipX, 1 - 2 * _FlipY) + float2(_FlipX, _FlipY);
                float3 baseCol = _Rainbow ? RandomRainbow(uv) : float3(1, 1, 1);
                float3 col = baseCol * Fade(WaveDistance(uv) * samplesSize / _Width);
                if (_Debug) {
                    float sampleIndex = uv.x * samplesSize;
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