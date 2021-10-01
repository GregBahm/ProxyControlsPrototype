using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpectrographLineRenderer : MonoBehaviour
{
    public GameObject LinePrefab;
    public int ResolutionPerLine;
    public int Lines;

    public Texture2D LineSource;

    public bool UpdatePositions;

    public float LineThickness;

    public Color StartColor;
    public Color EndColor;

    public float Diskify;
    public Vector3 RotationCenter;

    [Range(0,1)]
    public float Smoothing;

    private void Start()
    {
        for (int i = 0; i < Lines; i++)
        {
            CreateLine(i);
        }
        LinePrefab.SetActive(false);
    }

    private void CreateLine(int i)
    {
        float lineParam = (float)i / Lines;
        GameObject obj = Instantiate(LinePrefab);
        obj.transform.SetParent(transform, false);
        AudioLineBehavior behavior = obj.AddComponent<AudioLineBehavior>();
        behavior.LineParam = lineParam;
        behavior.Mothership = this;
    }
}

public class AudioLineBehavior : MonoBehaviour
{
    public float LineParam;

    public SpectrographLineRenderer Mothership;

    private LineRenderer lineRenderer;

    private void Start()
    {
        lineRenderer = GetComponent<LineRenderer>();
    }

    private void Update()
    {
        if(Mothership != null && Mothership.UpdatePositions)
        {
            lineRenderer.widthMultiplier = Mothership.LineThickness;
            lineRenderer.startColor = Color.Lerp(Mothership.StartColor, Mothership.EndColor, LineParam);
            lineRenderer.endColor = Color.Lerp(Mothership.StartColor, Mothership.EndColor, LineParam);
            UpdatePosition();
        }
    }

    private void UpdatePosition()
    {
        lineRenderer.positionCount = Mothership.ResolutionPerLine;
        Vector3[] basePositions = new Vector3[Mothership.ResolutionPerLine];
        for (int i = 0; i < Mothership.ResolutionPerLine; i++)
        {
            basePositions[i] = GetBasePosition(i);
        }
        Vector3[] finalPositions = new Vector3[Mothership.ResolutionPerLine];
        for (int i = 0; i < Mothership.ResolutionPerLine; i++)
        {
            finalPositions[i] = GetFinalPosition(basePositions, i);
        }
        lineRenderer.SetPositions(finalPositions);
    }


    //float angle = _Time.y;
    //float newX = cos(angle) * dir.x - sin(angle) * dir.z;
    //float newZ = sin(angle) * dir.x + cos(angle) * dir.z;
    //return float3(newX, dir.y* 5, newZ);
    private Vector3 GetFinalPosition(Vector3[] basePositions, int i)
    {
        float angle = (float)i / Mothership.ResolutionPerLine;
        angle *= Mothership.Diskify;
        Vector3 smoothedPosition = GetSmoothedPosition(basePositions, i);
        smoothedPosition -= Mothership.RotationCenter;
        float newX = Mathf.Cos(angle) * smoothedPosition.z - Mathf.Sin(angle) * smoothedPosition.x;
        float newY = Mathf.Sin(angle) * smoothedPosition.z + Mathf.Cos(angle) * smoothedPosition.x;
        Vector3 rotatedPoint = new Vector3(newY, smoothedPosition.y, newX);
        rotatedPoint += Mothership.RotationCenter;
        return rotatedPoint;
    }

    private Vector3 GetSmoothedPosition(Vector3[] basePositions, int i)
    {
        int previousIndex = Mathf.Max(0, i - 1);
        int nextIndex = Mathf.Min(i + 1, Mothership.ResolutionPerLine - 2);
        Vector3 prev = basePositions[previousIndex];
        Vector3 next = basePositions[nextIndex];
        Vector3 average = (prev + next) / 2;
        Vector3 current = basePositions[i];
        return Vector3.Lerp(current, average, Mothership.Smoothing);
    }

    private Vector3 GetBasePosition(int i)
    {
        float u = (float)i / Mothership.ResolutionPerLine;
        float v = LineParam;
        Color texSample = Mothership.LineSource.GetPixelBilinear(u, v);
        return new Vector3(v, texSample.r, u);
    }
}