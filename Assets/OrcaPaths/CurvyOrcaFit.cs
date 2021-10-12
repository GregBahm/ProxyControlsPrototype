using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CurvyOrcaFit : MonoBehaviour
{
    [SerializeField]
    ISplineSource splineSource;

    [SerializeField]
    Orca orca;
    
    [SerializeField]
    float CurveMarchDistance = .01f;

    float lastRelativePosition;

    void Start()
    {
        lastRelativePosition = splineSource.RelativePosition;
        UpdateOrcaOnSpline();
    }

    // Update is called once per frame
    void Update()
    {
        if (lastRelativePosition != splineSource.RelativePosition)
        {
            UpdateOrcaOnSpline();
            lastRelativePosition = splineSource.RelativePosition;
        }
    }

    private void PlaceJoint(Transform joint, float paramStartingPoint)
    {
        //Vector3 startingPoint = splineSou
        //TODO: Finish this
    }

    void UpdateOrcaOnSpline()
    {
        if (splineSource == null)
        {
            return;
        }


        for (int i = 0; i < orca.Joints.Length; i++)
        {
            float jointParam = splineSource.AbsolutePosition - i * CurveMarchDistance;

            if (jointParam >= 0)
            {
            }
            else
            {
                // we're trying to sample a point that is being clamped, just revert to the default position
                orca.Joints[i].localPosition = orca.OriginalLocalPoses[i].position;
                orca.Joints[i].localRotation = orca.OriginalLocalPoses[i].rotation;
            }
        }
    }
}

public interface ISplineSource
{
    float RelativePosition { get; }
    float AbsolutePosition { get; }

    Vector3 GetPositionAt(float param);
}