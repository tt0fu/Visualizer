float3 rgb2lab(float3 rgb) {
    float3x3 M1 = float3x3(
        +0.4122214708, +0.5363325363, +0.0514459929,
        +0.2119034982, +0.6806995451, +0.1073969566,
        +0.0883024619, +0.2817188376, +0.6299787005
    );

    float3x3 M2 = float3x3(
        +0.2104542553, +0.7936177850, -0.0040720468,
        +1.9779984951, -2.4285922050, +0.4505937099,
        +0.0259040371, +0.7827717662, -0.8086757660
    );
    float3 lms = mul(M1, rgb);
    float3 lms_ = pow(lms, 1.0 / 3.0);
    return mul(M2, lms_);
}

float3 lab2rgb(float3 lab) {
    float3x3 M1_inv = float3x3(
        +4.0767416621, -3.3077115913, +0.2309699292,
        -1.2684380046, +2.6097574011, -0.3413193965,
        -0.0041960863, -0.7034186147, +1.7076147010
    );

    float3x3 M2_inv = float3x3(
        +1.0000000000, +0.3963377774, +0.2158037573,
        +1.0000000000, -0.1055613458, -0.0638541728,
        +1.0000000000, -0.0894841775, -1.2914855480
    );
    float3 lms_ = mul(M2_inv, lab);
    float3 lms = lms_ * lms_ * lms_;
    return mul(M1_inv, lms);
}

float3 lch2lab(float3 lch) {
    float h = lch.b * UNITY_TWO_PI;
    return float3(lch.r, lch.g * cos(h), lch.g * sin(h));
}

float3 lab2lch(float3 lab) {
    float a = lab.g;
    float b = lab.b;
    return float3(lab.r, sqrt(a * a + b * b), atan2(b, a) / UNITY_TWO_PI);
}

float3 lch2rgb(float3 lch) {
    return lab2rgb(lch2lab(lch));
}

float3 rgb2lch(float3 rgb) {
    return lab2lch(rgb2lab(rgb));
}

float3 hueshift(float3 rgb, float shift) {
    float3 lch = rgb2lch(rgb);
    lch.b = frac(lch.b + shift + 1);
    return lch2rgb(lch);
}

float3 rainbow(float hue) {
    return lch2rgb(float3(_Lightness, _Chroma, hue));
}
