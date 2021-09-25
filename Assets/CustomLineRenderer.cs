using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomLineRenderer : MonoBehaviour
{
    public Material Mat;
    public BoxCollider BoundsSource;
    public const int LineResolution = 128;

    void Start()
    {
    }

    void Update()
    {
        Graphics.DrawProcedural(Mat, BoundsSource.bounds, MeshTopology.Lines, LineResolution);
    }
}
