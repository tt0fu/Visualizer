Shader "Waveform" {
    Properties {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _Width ("Width", Range(1, 200)) = 20
        _Height ("Height", Range(0, 10)) = 1.0
        [ToggleUI] _Debug ("Debug mode", Int) = 0
        [ToggleUI] _Rainbow ("Rainbow", Int) = 0
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

    frag_data vert(appdata vertex) {
        frag_data pixel;
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
            uint samples_size;
            float period;
            float focus;
            float scale_x;
            float chrono;

            float _Width;
            float _Height;
            bool _Debug;
            bool _Rainbow;
            float _Lightness;
            float _Chroma;
            float _RainbowScale;
            float _TimeScale;
            float _ChronoScale;

            float get_raw_sample(int sample_index) {
                if (sample_index < 0) {
                    sample_index += period * ceil((0 - sample_index) / period);
                }
                if (sample_index >= samples_size) {
                    sample_index -= period * ceil((sample_index - samples_size + 1) / period);
                }

                return samples.Load(sample_index) * _Height;
            }

            float get_sample(float sample_index) {
                float sample_left = get_raw_sample(floor(sample_index));
                float sample_right = get_raw_sample(ceil(sample_index));
                return lerp(sample_left, sample_right, frac(sample_index));
            }

            float fade(const float dist) {
                const float x = clamp(dist, 0, 1);
                return 1 - sqrt(1 - (x - 1) * (x - 1));
            }

            float pseudo_cross(float2 a, float2 b) {
                return a.x * b.y - b.x * a.y;
            }

            float point_to_segment_dist(float2 p1, float2 p2, float2 a) {
                p1.x *= scale_x;
                p2.x *= scale_x;
                a.x *= scale_x;
                float2 ap1 = p1 - a;
                float2 ap2 = p2 - a;
                float2 p1p2 = p2 - p1;
                if (dot(p1p2, -ap1) < 0 || dot(-p1p2, -ap2) < 0) {
                    return min(length(ap1), length(ap2));
                }
                if (length(p1p2) < 1e-12) {
                    return length(ap1);
                }
                return abs(pseudo_cross(ap1, ap2)) / length(p1p2);
            }

            float2 uv_point(float sample_index) {
                return float2(sample_index / samples_size, get_sample(sample_index) / 2 + 0.5);
            }

            float wave_distance(const float2 uv) {
                float sample_index = uv.x * samples_size;
                const int start_index = floor(sample_index - _Width);
                const int end_index = ceil(sample_index + _Width);
                float mn = 10;
                float2 last = uv_point(start_index);
                for (int index = start_index + 1; index < end_index; index++) {
                    const float2 cur = uv_point(index);
                    mn = min(mn, point_to_segment_dist(cur, last, uv));
                    last = cur;
                }
                return mn;
            }

            float3 debug_bar(float sample_index, float target, float3 color) {
                return color * fade(abs(sample_index - target) * scale_x / _Width);
            }

            #include "Oklab rainbow.cginc"

            float4 frag(frag_data pixel) :SV_Target {
                float3 base_col = float3(1, 1, 1);
                if (_Rainbow) {
                    float t = _Time.y * _TimeScale + chrono * _ChronoScale;
                    float hue = (pixel.uv.x - t) * _RainbowScale;
                    base_col = rainbow(hue);
                }
                float3 col = base_col * fade(wave_distance(pixel.uv) * samples_size / _Width);
                if (_Debug) {
                    float sample_index = pixel.uv.x * samples_size;
                    float focus_sample = samples_size * focus;
                    col += debug_bar(sample_index, focus_sample, float3(1, 0, 0));
                    col += debug_bar(sample_index, focus_sample - period / 2, float3(0, 1, 0));
                    col += debug_bar(sample_index, focus_sample + period / 2, float3(0, 1, 0));
                }
                return float4(col, 1);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}