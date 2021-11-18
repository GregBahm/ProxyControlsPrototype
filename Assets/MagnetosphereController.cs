using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class MagnetosphereController : MonoBehaviour
{
    public TextAsset LinesDefinition;
    public GameObject LinePrefab;
    private List<LineRenderer> lines;
    private float previousScale;
    private float baseLineScale;

    private void Start()
    {
        baseLineScale = LinePrefab.GetComponent<LineRenderer>().widthMultiplier;
        lines = new List<LineRenderer>();
        foreach (string line in LinesDefinition.text.Split('\r'))
        {
            lines.Add(CreateLine(line));
        }
    }

    private bool GetDidScaleChange()
    {
        return Mathf.Abs(previousScale - transform.localScale.x) > Mathf.Epsilon;
    }

    private float GetEffectiveLineWidth()
    {
        return baseLineScale * transform.localScale.x;
    }

    private void Update()
    {
        if(GetDidScaleChange())
        {
            foreach (LineRenderer line in lines)
            {
                line.widthMultiplier = GetEffectiveLineWidth();
            }
        }
        previousScale = transform.localScale.x;
    }

    private LineRenderer CreateLine(string line)
    {
        Vector3[] linePoints = GetLinePoints(line).ToArray();
        GameObject newLine = Instantiate(LinePrefab);
        LineRenderer lineRenderer = newLine.GetComponent<LineRenderer>();
        lineRenderer.positionCount = linePoints.Length;
        lineRenderer.SetPositions(linePoints);
        lineRenderer.widthMultiplier = GetEffectiveLineWidth();
        newLine.transform.parent = this.transform;
        return lineRenderer;
    }

    private IEnumerable<Vector3> GetLinePoints(string line)
    {
        string[] lineData = line.Split(',');
        for (int i = 0; i < lineData.Length; i+=5)
        {
            string xString = lineData[i + 2];
            string yString = lineData[i + 4];
            string zString = lineData[i + 3];
            float x = Convert.ToSingle(xString);
            float y = Convert.ToSingle(yString);
            float z = Convert.ToSingle(zString);
            yield return new Vector3(x, y, z);
        }
    }
}
