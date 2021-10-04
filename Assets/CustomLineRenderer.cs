using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomLineRenderer : MonoBehaviour
{
    public Material Mat;
    public BoxCollider BoundsSource;
    public const int LineResolution = 1024;
    public const int LinesCount = 1;

    void Start()
    {
    }

    void Update()
    {
        Graphics.DrawProcedural(Mat, BoundsSource.bounds, MeshTopology.LineStrip, LineResolution, LinesCount);
    }
}
