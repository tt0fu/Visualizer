using System;
using System.Linq;
using Lasp;
using UnityEngine;
using static UnityEngine.Shader;
using Unity.Burst;
using Unity.Mathematics;

[BurstCompile(CompileSynchronously = true)]
[RequireComponent(typeof(AudioLevelTracker))]
public class AudioReader : MonoBehaviour
{
    private AudioLevelTracker _tracker;
    private float _sampleRate;
    private static readonly int DftID = PropertyToID("dft");
    private static readonly int DftsSizeID = PropertyToID("dftSize");
    private static readonly int SamplesID = PropertyToID("samples");
    private static readonly int SamplesSizeID = PropertyToID("samplesSize");
    private static readonly int SamplesStartID = PropertyToID("samplesStart");
    private static readonly int PeriodID = PropertyToID("period");
    private static readonly int FocusID = PropertyToID("focus");
    private static readonly int CenterSampleID = PropertyToID("centerSample");
    private static readonly int ExpBinsID = PropertyToID("expBins");
    private static readonly int SampleRateID = PropertyToID("sampleRate");
    private static readonly int LowestFrequencyID = PropertyToID("lowestFrequency");
    private static readonly int BassID = PropertyToID("bass");
    private static readonly int ChronoID = PropertyToID("chrono");
    private int _dftSize;
    private int _samplesSize;
    private float _lowestFrequency;
    private int _expBins;
    private float2[] _dft;
    private float[] _magnitudes;
    private CircularArray<float> _samples;
    private float _bass;
    private float _chrono;
    private float _period;
    private float2 _phase;
    private float _centerSample;
    private ComputeBuffer _dftBuffer;
    private ComputeBuffer _samplesBuffer;


    [SerializeField] private Material[] dftMaterials;
    [SerializeField] private Material[] waveformMaterials;
    [SerializeField] private Material[] chronoMaterials;
    [SerializeField] private Material[] channelMaterials;

    [SerializeField] private int samplesSize = 4096;
    [SerializeField] private ComputeShader dftComputeShader;

    [SerializeField] [Range(0.0f, 50f)] public float waveScale = 2.5f;
    [SerializeField] [Range(0.0f, 1f)] public float waveScaleRegain = 0.04f;

    [SerializeField] [Range(0.0f, 1.0f)] private float focusPoint = 0.5f;
    [SerializeField] [Range(1, 4096)] private int dftSize = 512;


    private void Start()
    {
        _tracker = GetComponent<AudioLevelTracker>();
        _samplesSize = samplesSize;
        _sampleRate = AudioSystem.DefaultDevice.SampleRate;
        _dftSize = dftSize;
        _samplesSize = samplesSize;
        _dft = new float2[_dftSize];
        _magnitudes = new float[_dftSize];
        _samples = new CircularArray<float>(_samplesSize);
        _lowestFrequency = _sampleRate / _samplesSize;
        _chrono = 0;
        _period = 1;
        _phase = new float2(0, 0);
        _centerSample = _samplesSize * focusPoint;

        _dftBuffer = new ComputeBuffer(_dftSize, sizeof(float) * 2);
        _samplesBuffer = new ComputeBuffer(_samplesSize, sizeof(float));
    }

    private void OnDestroy()
    {
        _dftBuffer.Release();
        _samplesBuffer.Release();
    }

    private void UpdateCenterSample()
    {
        var angle = Mathf.Atan2(_phase.y, _phase.x) / (Mathf.PI * 2) - 0.25f;
        _centerSample = (angle + Mathf.Ceil(samplesSize * focusPoint / _period)) * _period;
    }

    private void UpdatePeriod()
    {
        var max = 0.0f;
        for (var i = 0; i < _dftSize; i++)
        {
            max = Mathf.Max(max, _magnitudes[i]);
        }

        var maxBin = 1;
        for (;
             maxBin < _dftSize - 1 &&
             (_magnitudes[maxBin] < _magnitudes[maxBin + 1] ||
              _magnitudes[maxBin] < _magnitudes[maxBin - 1] ||
              _magnitudes[maxBin] < max * 0.5);
             maxBin++)
        {
        }

        var frequency = Mathf.Pow(2, (float)maxBin / _expBins) * _lowestFrequency;

        _period = _sampleRate / frequency;
        _phase = _dft[maxBin];
    }

    private void UpdateSamples()
    {
        var newSamples = _tracker.audioDataSlice;
        waveScale *= (1 + Time.deltaTime * waveScaleRegain);
        foreach (var sample in newSamples)
        {
            waveScale = Math.Min(waveScale, 0.95f / Math.Abs(sample));
        }

        for (var i = 0; i < newSamples.Length; i++)
        {
            newSamples[i] *= waveScale;
        }

        _samples.Add(newSamples);
        _samplesBuffer.SetData(_samples.Array);
    }

    private void UpdateDft()
    {
        _expBins = (int)Mathf.Floor(_dftSize / Mathf.Log(_sampleRate / (2 * _lowestFrequency), 2));

        dftComputeShader.SetFloat(ExpBinsID, _expBins);
        dftComputeShader.SetFloat(SampleRateID, _sampleRate);
        dftComputeShader.SetFloat(LowestFrequencyID, _lowestFrequency);

        dftComputeShader.SetBuffer(0, SamplesID, _samplesBuffer);
        dftComputeShader.SetInt(SamplesSizeID, _samplesSize);
        dftComputeShader.SetInt(SamplesStartID, _samples.Start);

        dftComputeShader.SetBuffer(0, DftID, _dftBuffer);
        dftComputeShader.Dispatch(0, _dftSize / 256, 1, 1);
        _dftBuffer.GetData(_dft);

        for (var i = 0; i < _dftSize; i++)
        {
            _magnitudes[i] = math.length(_dft[i]);
        }
    }

    private void UpdateChrono()
    {
        _tracker.gain = 10 * Mathf.Log10(waveScale);
        _bass = _tracker.normalizedLevel;
        _chrono += Time.deltaTime * _bass;
    }

    private void UpdateMaterials()
    {
        foreach (var material in waveformMaterials)
        {
            material.SetBuffer(SamplesID, _samplesBuffer);
            material.SetInteger(SamplesSizeID, _samplesSize);
            material.SetInt(SamplesStartID, _samples.Start);
            material.SetFloat(PeriodID, _period);
            material.SetFloat(FocusID, focusPoint);
            material.SetFloat(CenterSampleID, _centerSample);
        }

        foreach (var material in dftMaterials)
        {
            material.SetBuffer(DftID, _dftBuffer);
            material.SetInteger(DftsSizeID, _dftSize);
            material.SetFloat(ExpBinsID, _expBins);
            material.SetFloat(LowestFrequencyID, _lowestFrequency);
        }

        foreach (var material in chronoMaterials)
        {
            material.SetFloat(ChronoID, _chrono);
        }

        foreach (var material in channelMaterials)
        {
            material.SetFloat(BassID, _bass);
        }
    }

    private void Update()
    {
        UpdateSamples();
        UpdateDft();
        UpdatePeriod();
        UpdateCenterSample();
        UpdateChrono();
        UpdateMaterials();
    }
}