using UnityEngine;
using UnityEngine.UI;
using static UnityEngine.Shader;
using Unity.Burst;

[BurstCompile(CompileSynchronously = true)]
[RequireComponent(typeof(Image))]
public class ScaleXSetter : MonoBehaviour
{
    private Image _image;
    private static readonly int ScaleXid = PropertyToID("scale_x");


    private void Start()
    {
        _image = GetComponent<Image>();
    }

    private void Update()
    {
        var rect = _image.rectTransform.rect;
        _image.material.SetFloat(ScaleXid, rect.width / rect.height);
    }
}