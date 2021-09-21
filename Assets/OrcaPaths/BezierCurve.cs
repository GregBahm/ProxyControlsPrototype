using UnityEngine;

public struct BezierCurve
{
    public Vector3 Start { get; }
    public Vector3 End { get; }

    public Vector3 StartAnchor { get; }
    public Vector3 EndAnchor { get; }

    public BezierCurve(Vector3 start, 
        Vector3 startAnchor, 
        Vector3 end, 
        Vector3 endAnchor) : this()
    {
        Start = start;
        End = end;
        StartAnchor = startAnchor;
        EndAnchor = endAnchor;
    }

    public Vector3 PlotPosition(float param)
    {
        Vector3 ab = Vector3.Lerp(Start, StartAnchor, param);
        Vector3 bc = Vector3.Lerp(StartAnchor, EndAnchor, param);
        Vector3 cd = Vector3.Lerp(EndAnchor, End, param);
        Vector3 abc = Vector3.Lerp(ab, bc, param);
        Vector3 bcd = Vector3.Lerp(bc, cd, param);
        return Vector3.Lerp(abc, bcd, param);
    }

    public float MeasureCurve(int precision)
    {
        float ret = 0;
        Vector3 lastPoint = Start;
        for (int i = 0; i < precision; i++)
        {
            float param = (float)i / precision;
            Vector3 nextPoint = PlotPosition(param);
            ret += (lastPoint = nextPoint).magnitude;
            lastPoint = nextPoint;
        }
        return ret;
    }
}