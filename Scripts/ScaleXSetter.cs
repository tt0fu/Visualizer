using UnityEngine;
using UnityEngine.UI;
using static UnityEngine.Shader;

[RequireComponent(typeof(Image))]
public class ScaleXSetter : MonoBehaviour
{
    private Image _image;
    private static readonly int ScaleXid = PropertyToID("scale_x");


    private void Start()
    {
        _image = GetComponent<Image>();
        var rect = _image.rectTransform.rect;
        _image.material.SetFloat(ScaleXid, rect.width / rect.height);
    }
}