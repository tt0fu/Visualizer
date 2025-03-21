using UnityEngine;
using UnityEngine.UI;
using static UnityEngine.Shader;
using Unity.Burst;

[BurstCompile(CompileSynchronously = true)]
[RequireComponent(typeof(Graphic))]
public class ScaleXSetter : MonoBehaviour
{
    private Graphic _graphic;
    private static readonly int ScaleXid = PropertyToID("scaleX");


    private void Start()
    {
        _graphic = GetComponent<Graphic>();
    }

    private void Update()
    {
        var rect = _graphic.rectTransform.rect;
        _graphic.material.SetFloat(ScaleXid, rect.width / rect.height);
    }
}