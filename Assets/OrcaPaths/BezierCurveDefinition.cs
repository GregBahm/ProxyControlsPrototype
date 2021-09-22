using System.Linq;
using UnityEngine;

[ExecuteInEditMode]
public class BezierCurveDefinition : MonoBehaviour
{
    public Color Color;
    public Waypoint[] Points;

    public bool Draw;
    public int PointsPerSegment;

    void Update()
    {
        if(Draw && Points.Length > 1 && Points.All(item => item != null))
        {
            BezierCurve[] curves = GetCurves();
            Vector3 lastPoint = curves[0].PlotPosition(0);
            for (int curveI = 0; curveI < curves.Length; curveI++)
            {
                for (int i = 0; i < PointsPerSegment; i++)
                {
                    float param = (float)(i + 1) / PointsPerSegment;
                    Vector3 newPoint = curves[curveI].PlotPosition(param);
                    Debug.DrawLine(lastPoint, newPoint, Color);
                    lastPoint = newPoint;
                }
            }
        }
        foreach (Waypoint waypoint in Points)
        {
            waypoint.gameObject.SetActive(Draw);
        }
    }

    public BezierCurveChain GetCurveChain()
    {
        BezierCurve[] curves = GetCurves();
        return new BezierCurveChain(curves);
    }

    private BezierCurve[] GetCurves()
    {
        BezierCurve[] ret = new BezierCurve[Points.Length - 1];
        for (int i = 1; i < Points.Length; i++)
        {
            Waypoint start = Points[i - 1];
            Waypoint end = Points[i];
            BezierCurve curve = GetCurve(start, end);
            ret[i - 1] = curve;
        }
        return ret;
    }

    private BezierCurve GetCurve(Waypoint start, Waypoint end)
    {

        Vector3 startAnchor = start.transform.position + start.transform.forward * start.Weight;
        Vector3 endAnchor = end.transform.position - end.transform.forward * end.Weight;
        return new BezierCurve(start.transform.position,
            startAnchor,
            end.transform.position,
            endAnchor);
    }
}