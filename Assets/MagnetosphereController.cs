using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class MagnetosphereController : MonoBehaviour
{
    public TextAsset LinesDefinition;
    public GameObject LinePrefab;

    private void Start()
    {
        foreach (string line in LinesDefinition.text.Split('\r'))
        {
            CreateLine(line);
        }
    }

    private void CreateLine(string line)
    {
        Vector3[] linePoints = GetLinePoints(line).ToArray();
        GameObject newLine = Instantiate(LinePrefab);
        LineRenderer renderer = newLine.GetComponent<LineRenderer>();
        renderer.positionCount = linePoints.Length;
        renderer.SetPositions(linePoints);
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
