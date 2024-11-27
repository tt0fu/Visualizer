using System;
using Lasp;
using UnityEngine;
using static UnityEngine.Shader;

[RequireComponent(typeof(AudioLevelTracker))]
public class AudioReader : MonoBehaviour
{
    private AudioLevelTracker _tracker;
    private float _sampleRate;
    private static readonly int DftID = PropertyToID("dft");
    private static readonly int DftsSizeID = PropertyToID("dft_size");
    private static readonly int SamplesID = PropertyToID("samples");
    private static readonly int SamplesSizeID = PropertyToID("samples_size");
    private static readonly int PeriodID = PropertyToID("period");
    private static readonly int FocusID = PropertyToID("focus");
    private static readonly int ExpBinsID = PropertyToID("exp_bins");
    private static readonly int SampleRateID = PropertyToID("sample_rate");
    private static readonly int LowestFrequencyID = PropertyToID("lowest_frequency");
    private static readonly int DftIterationCountID = PropertyToID("dft_iteration_count");
    private static readonly int ChronoID = PropertyToID("chrono");
    private int _dftSize;
    private int _samplesSize;
    private float _lowestFrequency;
    private int _expBins;
    private float[] _dft;
    private float[] _samples;
    private float[] _stabilizedSamples;
    private float _chrono;
    private ComputeBuffer _dftBuffer;
    private ComputeBuffer _samplesBuffer;
    private ComputeBuffer _stabilizedSamplesBuffer;


    public Material[] dftMaterials;
    public Material[] waveformMaterials;
    public Material[] chronoMaterials;

    public int samplesSize = 4096;
    public ComputeShader dftComputeShader;
    [Range(1, 128)] public int searchIterations = 16;
    [Range(0.0f, 10f)] public float waveScale = 2.5f;
    [Range(0.0f, 1.0f)] public float focusPoint = 0.5f;
    [Range(1, 4096)] public int dftIterationCount = 4096;

    [Range(0.0f, 100.0f)] public float chronoThreshold = 15f;
    [Range(0.0f, 1.0f)] public float chronoRightBorder = 0.1f;


    private void Start()
    {
        _tracker = GetComponent<AudioLevelTracker>();
        _samplesSize = samplesSize;
        _sampleRate = AudioSystem.DefaultDevice.SampleRate;
        _dftSize = 512;
        _samplesSize = samplesSize;
        _dft = new float[_dftSize];
        _samples = new float[_samplesSize];
        _stabilizedSamples = new float[_samplesSize];
        _lowestFrequency = _sampleRate / _samplesSize;
        _chrono = 0;

        _dftBuffer = new ComputeBuffer(_dftSize, sizeof(float));
        _samplesBuffer = new ComputeBuffer(_samplesSize, sizeof(float));
        _stabilizedSamplesBuffer = new ComputeBuffer(_samplesSize, sizeof(float));
    }

    private void OnDestroy()
    {
        _dftBuffer.Release();
        _samplesBuffer.Release();
        _stabilizedSamplesBuffer.Release();
    }

    private float GetSample(float index)
    {
        index = (float.IsNaN(index) || float.IsInfinity(index)) ? 0 : Math.Clamp(index, 1, _samplesSize - 2);
        var left = _samples[(int)Math.Floor(index)];
        var right = _samples[(int)Math.Ceiling(index)];
        var frac = index - (float)Math.Floor(index);
        return left * (1 - frac) + right * frac;
    }

    private float GetSample(float index, float period)
    {
        if (index < 0)
        {
            index += period * (float)Math.Ceiling((-index - 1) / period);
        }

        if (index >= samplesSize)
        {
            index -= period * (float)Math.Ceiling((index - samplesSize + 1) / period);
        }

        return GetSample(index);
    }

    private float CenterSample(float start, float period)
    {
        var left = start - period / 2;
        var right = start + period / 2;
        for (var i = 0; i < searchIterations; i++)
        {
            var middle1 = left + (right - left) / 3;
            var middle2 = right - (right - left) / 3;
            if (GetSample(middle1) > GetSample(middle2))
            {
                right = middle1;
            }
            else
            {
                left = middle2;
            }
        }

        left = right - (period / 2);

        for (var i = 0; i < searchIterations; i++)
        {
            var middle = (right + left) / 2;
            if (GetSample(middle) < 0)
            {
                left = middle;
            }
            else
            {
                right = middle;
            }
        }

        return left;
    }

    private float GetFrequency(float bin)
    {
        return (float)Math.Pow(2, bin / _expBins) * _lowestFrequency;
    }

    private float PeriodFromDft()
    {
        var max = 0.0f;
        var maxBin = 100f;
        for (var i = 0; i < _dftSize; i++)
        {
            var cur = _dft[i] * (_dftSize - i);
            if (!(cur > max))
            {
                continue;
            }

            max = cur;
            maxBin = i;
        }

        return _sampleRate / GetFrequency(maxBin);
    }

    private float ChronoScale()
    {
        var max = 0.0f;
        for (var i = 0; i < _dftSize * chronoRightBorder; i++)
        {
            var cur = _dft[i] * (_dftSize - i);
            if (!(cur > max))
            {
                continue;
            }

            max = cur;
        }

        return Math.Clamp(0.5f * (max - chronoThreshold) + 1, 0, 1);
    }

    private void UpdateSamples()
    {
        var newSamples = _tracker.audioDataSlice.ToArray();
        var shift = newSamples.Length;
        for (var i = 0; i + shift < _samplesSize; i++)
        {
            _samples[i] = _samples[i + shift];
        }

        for (int i = 0; i < shift; i++)
        {
            _samples[_samplesSize - shift + i] = newSamples[i] * waveScale;
        }
    }

    private void Update()
    {
        UpdateSamples();
        _samplesBuffer.SetData(_samples);
        _expBins = (int)Math.Floor(_dftSize / Math.Log(_sampleRate / (2 * _lowestFrequency), 2));
        dftComputeShader.SetFloat(ExpBinsID, _expBins);
        dftComputeShader.SetFloat(SampleRateID, _sampleRate);
        dftComputeShader.SetFloat(LowestFrequencyID, _lowestFrequency);
        dftComputeShader.SetFloat(DftIterationCountID, dftIterationCount);
        dftComputeShader.SetBuffer(0, SamplesID, _samplesBuffer);
        dftComputeShader.SetInt(SamplesSizeID, _samplesSize);
        dftComputeShader.SetBuffer(0, DftID, _dftBuffer);
        dftComputeShader.Dispatch(0, _dftSize, 1, 1);
        _dftBuffer.GetData(_dft);

        var period = PeriodFromDft();
        _chrono += Time.deltaTime * ChronoScale();
        var middle = CenterSample(_samplesSize * focusPoint, period);
        for (var i = 0; i < samplesSize; i++)
        {
            _stabilizedSamples[i] = GetSample(i + (middle - samplesSize * focusPoint), period);
        }

        _stabilizedSamplesBuffer.SetData(_stabilizedSamples);

        foreach (var material in waveformMaterials)
        {
            material.SetBuffer(SamplesID, _stabilizedSamplesBuffer);
            // material.SetBuffer(SamplesID, _samplesBuffer);
            material.SetInteger(SamplesSizeID, _samplesSize);
            material.SetFloat(PeriodID, period);
            material.SetFloat(FocusID, focusPoint);
        }

        foreach (var material in dftMaterials)
        {
            material.SetBuffer(DftID, _dftBuffer);
            material.SetInteger(DftsSizeID, _dftSize);
        }

        foreach (var material in chronoMaterials)
        {
            material.SetFloat(ChronoID, _chrono);
        }
    }
}