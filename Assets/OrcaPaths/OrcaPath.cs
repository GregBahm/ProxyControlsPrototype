using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class OrcaPath : MonoBehaviour
{
    public BezierCurveDefinition Curve;
    public Orca Orca;

    [Range(0, 1)]
    public float PathProgress = 1;

    public float JointSpan = .01f;

    public int IndicatorsCount;

    private void Start()
    {
        SkinnedMeshRenderer orcaMesh = Orca.gameObject.GetComponentInChildren<SkinnedMeshRenderer>();
        orcaMesh.material.SetColor("_EmissionColor", Curve.Color);
        foreach(Waypoint waypoint in Curve.Points)
        {
            MeshRenderer waypointMesh = waypoint.gameObject.GetComponent<MeshRenderer>();
            waypointMesh.material.color = Curve.Color;
        }

        BezierCurveChain chain = Curve.GetCurveChain();
        for (int i = 1; i < IndicatorsCount; i++)
        {
            GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
            float param = (float)i / IndicatorsCount;
            param *= Curve.Points.Length;
            Vector3 pos = chain.PlotPosition(param);
            box.transform.position = pos;
            box.transform.localScale = new Vector3(.1f, .1f, .1f);
        }
    }

    private void Update()
    {
        PlaceOnPath(Orca, PathProgress, JointSpan);
    }

    private void PlaceOnPath(Orca orca, float param, float jointSpan)
    {
        param *= Curve.Points.Length;
        BezierCurveChain chain = Curve.GetCurveChain();
        orca.Joints[0].position = chain.PlotPosition(param);
        for (int i = 0; i < orca.Joints.Length; i++)
        {
            float jointParam = param - i * jointSpan;
            Vector3 jointPos = chain.PlotPosition(jointParam);
            orca.Joints[i].position = jointPos;

            Vector3 lookTarget = chain.PlotPosition(jointParam - jointSpan);
            orca.Joints[i].LookAt(lookTarget);
        }
    }
}


public class BezierCurveChain
{
    private readonly IReadOnlyList<BezierCurve> curves;

    public BezierCurveChain(IEnumerable<BezierCurve> curves)
    {
        this.curves = curves.ToList();
    }

    public Vector3 PlotPosition(float param)
    {
        if(param >= curves.Count)
        {
            return curves.Last().PlotPosition(1);
        }
        int curveIndex = Mathf.Clamp(Mathf.FloorToInt(param), 0, curves.Count - 1);
        BezierCurve curve = curves[curveIndex];
        float subParam = param % 1;
        return curve.PlotPosition(subParam);
    }
}