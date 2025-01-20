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
    private static readonly int DftsSizeID = PropertyToID("dft_size");
    private static readonly int SamplesID = PropertyToID("samples");
    private static readonly int SamplesSizeID = PropertyToID("samples_size");
    private static readonly int SamplesStartID = PropertyToID("samples_start");
    private static readonly int PeriodID = PropertyToID("period");
    private static readonly int FocusID = PropertyToID("focus");
    private static readonly int CenterSampleID = PropertyToID("center_sample");
    private static readonly int ExpBinsID = PropertyToID("exp_bins");
    private static readonly int SampleRateID = PropertyToID("sample_rate");
    private static readonly int LowestFrequencyID = PropertyToID("lowest_frequency");
    private static readonly int DftIterationCountID = PropertyToID("dft_iteration_count");
    private static readonly int ChronoID = PropertyToID("chrono");
    private int _dftSize;
    private int _samplesSize;
    private float _lowestFrequency;
    private int _expBins;
    private float3[] _dft;
    private CircularArray<float> _samples;
    private float _chrono;
    private float _period;
    private float2 _phase;
    private float _centerSample;
    private ComputeBuffer _dftBuffer;
    private ComputeBuffer _samplesBuffer;


    [SerializeField] private Material[] dftMaterials;
    [SerializeField] private Material[] waveformMaterials;
    [SerializeField] private Material[] chronoMaterials;

    [SerializeField] private int samplesSize = 4096;
    [SerializeField] private ComputeShader dftComputeShader;

    [SerializeField] [Range(0.0f, 10f)] public float waveScale = 2.5f;

    [SerializeField] [Range(0.0f, 1.0f)] private float focusPoint = 0.5f;
    [SerializeField] [Range(1, 4096)] private int dftIterationCount = 4096;


    private void Start()
    {
        _tracker = GetComponent<AudioLevelTracker>();
        _samplesSize = samplesSize;
        _sampleRate = AudioSystem.DefaultDevice.SampleRate;
        _dftSize = 512;
        _samplesSize = samplesSize;
        _dft = new float3[_dftSize];
        _samples = new CircularArray<float>(_samplesSize);
        _lowestFrequency = _sampleRate / _samplesSize;
        _chrono = 0;
        _period = 1;
        _phase = new float2(0, 0);
        _centerSample = _samplesSize * focusPoint;

        _dftBuffer = new ComputeBuffer(_dftSize, sizeof(float) * 3);
        _samplesBuffer = new ComputeBuffer(_samplesSize, sizeof(float));
    }

    private void OnDestroy()
    {
        _dftBuffer.Release();
        _samplesBuffer.Release();
    }

    private void UpdateCenterSample()
    {
        var angle = Mathf.Atan2(_phase.y, _phase.x) / (Mathf.PI * 2) + 0.5f;
        _centerSample = (angle + Mathf.Floor(samplesSize * focusPoint / _period)) * _period;
    }

    private float GetFrequency(float bin)
    {
        return Mathf.Pow(2, bin / _expBins) * _lowestFrequency;
    }

    private void UpdatePeriod()
    {
        var max = 0.0f;
        var maxBin = _dftSize;
        for (var i = 0; i < _dftSize; i++)
        {
            var cur = _dft[i].x * (_dftSize - i);
            if (cur < max)
            {
                continue;
            }

            max = cur;
            maxBin = i;
        }

        _period = _sampleRate / GetFrequency(maxBin);
        _phase = _dft[maxBin].yz;
    }

    private void UpdateSamples()
    {
        var newSamples = _tracker.audioDataSlice;
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
        dftComputeShader.SetFloat(DftIterationCountID, dftIterationCount);

        dftComputeShader.SetBuffer(0, SamplesID, _samplesBuffer);
        dftComputeShader.SetInt(SamplesSizeID, _samplesSize);
        dftComputeShader.SetInt(SamplesStartID, _samples.Start);

        dftComputeShader.SetBuffer(0, DftID, _dftBuffer);
        dftComputeShader.Dispatch(0, _dftSize, 1, 1);
        _dftBuffer.GetData(_dft);
    }

    private void UpdateChrono()
    {
        _tracker.gain = 10 * Mathf.Log10(waveScale);
        _chrono += Time.deltaTime * _tracker.normalizedLevel;
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
        }

        foreach (var material in chronoMaterials)
        {
            material.SetFloat(ChronoID, _chrono);
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