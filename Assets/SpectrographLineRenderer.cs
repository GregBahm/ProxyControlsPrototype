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

    [Range(0, 1)]
    public float Diskify;

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
        for (int i = 0; i < Mothership.ResolutionPerLine; i++)
        {
            Vector3 pos = GetPosition(i);
            lineRenderer.SetPosition(i, pos);
        }
    }

    private Vector3 GetPosition(int i)
    {
        float u = (float)i / Mothership.ResolutionPerLine;
        float v = LineParam;
        Color col = Mothership.LineSource.GetPixelBilinear(u, v);



        return new Vector3(v, col.r, u);
    }
}