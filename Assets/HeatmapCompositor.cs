using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeatmapCompositor : MonoBehaviour
{
    [SerializeField]
    private Material compositionMat;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, compositionMat);
    }
}
