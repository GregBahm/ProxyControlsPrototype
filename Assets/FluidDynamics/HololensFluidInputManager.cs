using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HololensFluidInputManager : MonoBehaviour
{
    public FluidSimulator Sim;

    public float Deadzone = .1f;

    private Transform translationHelper;

    public PinchDetector LeftPinchDetector;

    public Transform TargetTransform;

    public float RotationSpeed = 1000;

    public ProxyButton MoveButton;
    public ProxyButton RotateButton;
    public ProxyButton ScaleButton;
    public ProxyButton PlayPause;

    public ImpulserScript LeftEffector;
    public ImpulserScript RightEffector;

    public enum LeftHandToolMode
    {
        Move,
        Rotate,
        Scale
    }

    public LeftHandToolMode toolMode;

    private void Start()
    {
        translationHelper = new GameObject("Translation Helper").transform;
        MoveButton.Clicked += OnMoveClicked;
        RotateButton.Clicked += OnRotateClicked;
        ScaleButton.Clicked += OnScaleClicked;
    }

    private void OnMoveClicked(object sender, EventArgs e)
    {
        toolMode = LeftHandToolMode.Move;
        UpdateToolButtonToggles();
    }

    private void OnRotateClicked(object sender, EventArgs e)
    {
        toolMode = LeftHandToolMode.Rotate;
        UpdateToolButtonToggles();
    }

    private void OnScaleClicked(object sender, EventArgs e)
    {
        toolMode = LeftHandToolMode.Scale;
        UpdateToolButtonToggles();
    }

    private void UpdateToolButtonToggles()
    {
        MoveButton.Toggled = toolMode == LeftHandToolMode.Move;
        RotateButton.Toggled = toolMode == LeftHandToolMode.Rotate;
        ScaleButton.Toggled = toolMode == LeftHandToolMode.Scale;
    }

    void Update()
    {
        UpdatePlayPause();
        UpdatePinchAndDrag();
        UpdateEffectors();
    }

    private void UpdatePlayPause()
    {
        Sim.enabled = PlayPause.Toggled;
        LeftEffector.enabled = PlayPause.Toggled;
        RightEffector.enabled = PlayPause.Toggled;
    }

    private void SetEffector(Transform proxy, HandProxy hand)
    {
        proxy.position = hand.IndexTip.position;
        proxy.rotation = Quaternion.LookRotation(hand.IndexTip.position - hand.IndexDistal.position);
    }

    private void UpdateEffectors()
    {
        SetEffector(LeftEffector.transform, Hands.Instance.LeftHandProxy);
        SetEffector(RightEffector.transform, Hands.Instance.RightHandProxy);
    }

    private void UpdatePinchAndDrag()
    {
        switch (toolMode)
        {
            case LeftHandToolMode.Move:
                UpdateDragging();
                break;
            case LeftHandToolMode.Rotate:
                UpdateRotating();
                break;
            case LeftHandToolMode.Scale:
            default:
                UpdateResizing();
                break;
        }
    }

    private float startDist;
    private float startScale;

    private void UpdateResizing()
    {
        if (LeftPinchDetector.PinchBeginning)
        {
            translationHelper.position = LeftPinchDetector.PinchPoint.position;
            startDist = (TargetTransform.position - translationHelper.position).magnitude;
            startScale = TargetTransform.localScale.x;
        }
        if(LeftPinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
            float newDist = (TargetTransform.position - translationHelper.position).magnitude;
            float diff = newDist / startDist;
            float newScale = startScale * diff;
            TargetTransform.localScale = new Vector3(newScale, newScale, newScale);
        }
    }

    private Plane planeOfRotation;
    private bool wasRotating;
    private Quaternion startRot;
    private void UpdateRotating()
    {
        if(!wasRotating && LeftPinchDetector.PinchBeginning)
        {
            translationHelper.position = LeftPinchDetector.PinchPoint.position;
            Vector3 toPinch = Camera.main.transform.position - translationHelper.position;
            Vector3 rotationPlane = Vector3.Cross(toPinch, Vector3.up).normalized;
            planeOfRotation = new Plane(rotationPlane, translationHelper.position);
            startRot = TargetTransform.rotation;
        }
        if(LeftPinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
            float distToRotPlane = -planeOfRotation.GetDistanceToPoint(translationHelper.position);
            Quaternion rot = Quaternion.AngleAxis(distToRotPlane * RotationSpeed, Vector3.up);
            TargetTransform.rotation = startRot * rot;
        }
        wasRotating = LeftPinchDetector.Pinching;
    }

    private Vector3 transformHelperStartPos;
    private Vector3 mainStageStartPos;
    private bool wasDragging;
    private void UpdateDragging()
    {
        if(!wasDragging && LeftPinchDetector.PinchBeginning)
        {
            translationHelper.position = LeftPinchDetector.PinchPoint.position;
            transformHelperStartPos = translationHelper.position;
            mainStageStartPos = TargetTransform.position;
        }
        if(LeftPinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
            TargetTransform.position = mainStageStartPos + (translationHelper.position - transformHelperStartPos);
        }
        wasDragging = LeftPinchDetector.Pinching;
    }
    
    private Vector3 GetDeadzoneMovement()
    {
        Vector3 toTarget = LeftPinchDetector.PinchPoint.position - translationHelper.position;
        float distToTarget = toTarget.magnitude;
        float deadDist = Mathf.Max(0, distToTarget - Deadzone);
        return translationHelper.position + toTarget.normalized * deadDist;
    }
}
