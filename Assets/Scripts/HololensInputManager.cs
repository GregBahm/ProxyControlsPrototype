using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HololensInputManager : MonoBehaviour
{
    public float Deadzone = .1f;

    private Transform translationHelper;

    public PinchDetector LeftPinchDetector;

    public Transform TargetTransform;

    public ProxyButton MoveButton;
    public ProxyButton RotateButton;
    public ProxyButton ScaleButton;

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
        UpdatePinchAndDrag();
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

    private Quaternion startRotation;
    private float addedRotation;
    private Plane rotationPlane;
    private bool wasRotating;
    private void UpdateRotating()
    {
        if(!wasRotating && LeftPinchDetector.PinchBeginning)
        {
            startRotation = TargetTransform.rotation;
            translationHelper.position = LeftPinchDetector.PinchPoint.position;
        }
        if(LeftPinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
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
