using System;
using UnityEngine;
using static UnityEngine.Shader;
using Unity.Burst;
using UnityEngine.SceneManagement;
using UnityEngine.Serialization;

[BurstCompile(CompileSynchronously = true)]
[RequireComponent(typeof(AudioReader))]
public class KeyboardControls : MonoBehaviour
{
    private static readonly int WidthID = PropertyToID("_Width");
    private static readonly int DebugID = PropertyToID("_Debug");
    private static readonly int DisableStabilizationID = PropertyToID("_DisableStabilization");
    [SerializeField] private Material waveformMaterial;
    private AudioReader _audioReader;

    public void Start()
    {
        _audioReader = GetComponent<AudioReader>();
    }

    private void OnGUI()
    {
        var e = Event.current;
        if (!e.isKey || e.type == EventType.KeyUp) return;
        float value;
        switch (e.keyCode)
        {
            case KeyCode.UpArrow:
                _audioReader.waveScale = Math.Clamp(_audioReader.waveScale + 0.05f, 0f, 10f);
                break;
            case KeyCode.DownArrow:
                _audioReader.waveScale = Math.Clamp(_audioReader.waveScale - 0.05f, 0f, 10f);
                break;
            case KeyCode.RightArrow:
                value = waveformMaterial.GetFloat(WidthID) + 1;
                waveformMaterial.SetFloat(WidthID, Math.Clamp(value, 0, 200));
                break;
            case KeyCode.LeftArrow:
                value = waveformMaterial.GetFloat(WidthID) - 1;
                waveformMaterial.SetFloat(WidthID, Math.Clamp(value, 0, 200));
                break;
            case KeyCode.F1:
                waveformMaterial.SetInt(DebugID, 1 - waveformMaterial.GetInt(DebugID));
                break;
            case KeyCode.F2:
                waveformMaterial.SetInt(DisableStabilizationID, 1 - waveformMaterial.GetInt(DisableStabilizationID));
                break;
            case KeyCode.Alpha1:
                SceneManager.LoadScene(0);
                break;
            case KeyCode.Alpha2:
                SceneManager.LoadScene(1);
                break;
            case KeyCode.Alpha3:
                SceneManager.LoadScene(2);
                break;
            default:
                return;
        }
    }
}