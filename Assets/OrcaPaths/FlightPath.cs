using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using UnityEngine;

public class FlightPath
{
    private readonly BezierCurve path;
    private readonly float rotationUpWeight;
    private readonly float rotationStrength;
    private readonly int iterations;
    private readonly Vector3[] positions;
    private readonly Quaternion[] rotations;

    public ReadOnlyCollection<Pose> Poses { get; }
    
    public FlightPath(BezierCurve path, 
        float rotationUpWeight, 
        float rotationStrength,
        int iterations,
        Vector3 lastShipPosition,
        Vector3 lastUpRotation)
    {
        this.path = path;
        this.rotationUpWeight = rotationUpWeight;
        this.rotationStrength = rotationStrength;
        this.iterations = iterations;
        this.positions = GetPositions();
        this.rotations = GetRotations(lastShipPosition, lastUpRotation);
        Poses = GetPoses().ToList().AsReadOnly();
    }

    private IEnumerable<Pose> GetPoses()
    {
        for (int i = 0; i < iterations; i++)
        {
            yield return new Pose(positions[i], rotations[i]);
        }
    }

    private Vector3[] GetPositions()
    {
        Vector3[] ret = new Vector3[iterations];
        for (int i = 0; i < iterations; i++)
        {
            float param = (float)i / iterations;
            ret[i] = path.PlotPosition(param);
        }
        return ret;
    }

    private Quaternion[] GetRotations(Vector3 lastPos, Vector3 lastUpRotation)
    {

        Quaternion[] ret = new Quaternion[iterations];
        
        ret[0] = GetStartingRotation(lastPos, lastUpRotation);
        for (int i = 1; i < iterations - 1; i++)
        {
            Vector3 previous = positions[i - 1];
            Vector3 current = positions[i];
            Vector3 next = positions[i + 1];
            Quaternion rot = GetShipRotation(previous, current, next, lastUpRotation);
            ret[i] = rot;
            lastUpRotation = rot * Vector3.up;
        }
        ret[iterations - 1] = GetEndingRotation(lastUpRotation);

        return ret;
    }

    private Quaternion GetStartingRotation(Vector3 lastPos, Vector3 lastUp)
    {
        Vector3 current = positions[0];
        Vector3 next = positions[1];
        return GetShipRotation(lastPos, current, next, lastUp);
    }

    private Quaternion GetEndingRotation(Vector3 lastUpRotation)
    {
        Vector3 current = positions[iterations - 1];
        Vector3 previous = positions[iterations - 2];
        return GetShipRotation(previous, current, path.End, lastUpRotation);
    }

    private Quaternion GetShipRotation(
        Vector3 previous,
        Vector3 current,
        Vector3 next,
        Vector3 previousUp)
    {
        Vector3 toCurrent = current - previous;
        Vector3 toNext = next - current;
        Vector3 average = (toCurrent + toNext) / 2;

        Vector3 maxTilt = (toNext.normalized - toCurrent.normalized) / 2;

        float mag = Mathf.Pow(maxTilt.magnitude, rotationUpWeight);
        Vector3 up = Vector3.Lerp(Vector3.up, maxTilt, mag);

        Vector3 progressive = Vector3.Lerp(previousUp, up, rotationStrength);
        return Quaternion.LookRotation(average, progressive);
    }

    private Vector3 GetShipPosition(float pathProgress)
    {
        return path.PlotPosition(pathProgress);
    }
}