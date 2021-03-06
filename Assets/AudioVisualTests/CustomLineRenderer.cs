    using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomLineRenderer : MonoBehaviour
{
    public Material Mat;
    public BoxCollider BoundsSource;
    public const int LineResolution = 512;
    public const int LinesCount = 8;

    void Start()
    {
    }

    void Update()
    {
        Mat.SetMatrix("_Transform", transform.localToWorldMatrix);
        Graphics.DrawProcedural(Mat, BoundsSource.bounds, MeshTopology.LineStrip, LineResolution, LinesCount);
    }
}
