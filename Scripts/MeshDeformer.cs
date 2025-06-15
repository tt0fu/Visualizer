using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class MeshDeformer : MonoBehaviour
{
    private Mesh _mesh;

    private void Start()
    {
        _mesh = GetComponent<MeshFilter>().mesh;
        _mesh.MarkDynamic();
    }

    private static void UpdateVertex(ref Vector3 v)
    {
        v = new Vector3(v.x, v.y, Mathf.Sin(((v.x * v.x + v.y * v.y) + Time.time) * 10f) * 0.1f);
    }

    private void Update()
    {
        var newVertices = _mesh.vertices;
        for (var i = 0; i < newVertices.Length; i++)
        {
            UpdateVertex(ref newVertices[i]);
        }

        _mesh.vertices = newVertices;

        // _mesh.RecalculateNormals();
        // _mesh.RecalculateBounds();
        // _mesh.RecalculateTangents();
    }
}