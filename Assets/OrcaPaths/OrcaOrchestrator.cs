using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OrcaOrchestrator : MonoBehaviour
{
    public OrcaPath[] OrcaPaths;

    [Range(0, .8f)]
    public float SceneProgress;

    private void Update()
    {
        foreach(OrcaPath path in OrcaPaths)
        {
            path.PathProgress = SceneProgress;
            path.Curve.Draw = false;
        }
    }
}
