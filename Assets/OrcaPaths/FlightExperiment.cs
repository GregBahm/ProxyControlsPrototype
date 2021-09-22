using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class FlightExperiment : MonoBehaviour
{
    public Waypoint[] Waypoints;
    public Orca Orca;
    public int Iterations;

    public float RotationUpWeight;
    public float RotationStrength;

    [Range(0, 3)]
    public float WhaleProgress = 1;

    [Range(0, 1)]
    public float OrcaIterationScale = 1;

    public float JointSpan = .01f;

    private OrcaPathDisplay[] pathSegments;

    public FlightExperimentMode Mode;

    public enum FlightExperimentMode
    {
        Many,
        One
    }

    private void Start()
    {
        pathSegments = CreatePathSegments().ToArray();
    }

    private IEnumerable<OrcaPathDisplay> CreatePathSegments()
    {
        for (int i = 1; i < Waypoints.Length; i++)
        {
            Waypoint start = Waypoints[i - 1];
            Waypoint end = Waypoints[i];
            Orca[] shipIterations = CreateShipIterations().ToArray();
            yield return new OrcaPathDisplay(start, end, shipIterations, this);
        }
    }

    private void Update()
    {
        UpdateManyMode();
        UpdateOneMode();
    }

    private void UpdateOneMode()
    {
        if(Mode == FlightExperimentMode.One)
        {
            Orca.gameObject.SetActive(true);
            PlaceOnPath(Orca, WhaleProgress, JointSpan);
        }
        else
        {
            Orca.gameObject.SetActive(false);
        }
    }

    private void PlaceOnPath(Orca orca, float param, float jointSpan)
    {
        BezierCurveChain chain = GetChain();
        orca.Joints[0].position = chain.PlotPosition(param);
        for (int i = 0; i < orca.Joints.Length; i++)
        {
            float jointParam = param - i * jointSpan;
            Vector3 jointPos = chain.PlotPosition(jointParam);
            orca.Joints[i].position = jointPos;

            Vector3 lookTarget = chain.PlotPosition(jointParam - jointSpan);
            orca.Joints[i].LookAt(lookTarget);

            Debug.DrawLine(jointPos, lookTarget);
        }
    }

    private BezierCurveChain GetChain()
    {
        return new BezierCurveChain(pathSegments.Select(item => item.GetCurrentPath()));
    }

    private void UpdateManyMode()
    {
        Vector3 lastPos = Waypoints[0].transform.position - Waypoints[0].transform.forward;
        Vector3 lastUp = Vector3.up;
        foreach (OrcaPathDisplay segment in pathSegments)
        {
            segment.SetIterations(lastPos, lastUp);
            lastUp = segment.LastIteration.transform.up;
            lastPos = segment.LastIteration.transform.position;
            if (Mode != FlightExperimentMode.Many)
            {
                segment.DeactivateAll();
            }
        }
    }

    private IEnumerable<Orca> CreateShipIterations()
    {
        for (int i = 0; i < Iterations; i++)
        {
            GameObject newShip = Instantiate(Orca.gameObject);
            Orca orca = newShip.GetComponent<Orca>();
            yield return orca;
        }
    }
}

public class OrcaPathDisplay
{
    public Waypoint StartPoint { get; }
    public Waypoint EndPoint { get; }

    private readonly FlightExperiment mothership;

    private readonly Orca[]  orcaIterations;

    public Orca LastIteration { get { return orcaIterations[orcaIterations.Length - 1]; } }

    public OrcaPathDisplay(Waypoint startPoint, Waypoint endPoint, Orca[] orcaIterations, FlightExperiment mothership)
    {
        StartPoint = startPoint;
        EndPoint = endPoint;
        this.orcaIterations = orcaIterations;
        this.mothership = mothership;
    }

    public void DeactivateAll()
    {
        foreach (Orca orca in orcaIterations)
        {
            orca.gameObject.SetActive(false);
        }
    }

    public void SetIterations(Vector3 fromPosition, Vector3 fromUp)
    {
        FlightPath flightPath = new FlightPath(GetCurrentPath(),
            mothership.RotationUpWeight,
            mothership.RotationStrength,
            mothership.Iterations,
            fromPosition,
            fromUp);

        for (int i = 0; i < orcaIterations.Length; i++)
        {
            orcaIterations[i].gameObject.SetActive(true);
            orcaIterations[i].transform.localScale = new Vector3(mothership.OrcaIterationScale, mothership.OrcaIterationScale, mothership.OrcaIterationScale);
            orcaIterations[i].transform.position = flightPath.Poses[i].position;
            orcaIterations[i].transform.rotation = flightPath.Poses[i].rotation;
        }
    }

    public BezierCurve GetCurrentPath()
    {
        Vector3 startAnchor = StartPoint.transform.position + StartPoint.transform.forward * StartPoint.Weight;
        Vector3 endAnchor = EndPoint.transform.position - EndPoint.transform.forward * EndPoint.Weight;
        return new BezierCurve(StartPoint.transform.position,
            startAnchor,
            EndPoint.transform.position,
            endAnchor);
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
        int curveIndex = Mathf.Min(curves.Count, Mathf.FloorToInt(param));
        BezierCurve curve = curves[curveIndex];
        float subParam = param % 1;
        return curve.PlotPosition(subParam);
    }
}