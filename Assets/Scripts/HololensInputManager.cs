using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HololensInputManager : MonoBehaviour
{

    public float Deadzone = .1f;

    private Transform translationHelper;
    private Transform rotationHelper;

    public PinchDetector PinchDetector;

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
        rotationHelper = new GameObject("Rotation Helper").transform;
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
    private bool wasResizing;
    private void UpdateResizing()
    {
        if (!wasResizing && PinchDetector.PinchBeginning)
        {
            translationHelper.position = PinchDetector.PinchPoint.position;
            startDist = (TargetTransform.position - translationHelper.position).magnitude;
            startScale = TargetTransform.localScale.x;
        }
        if(PinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
            float newDist = (TargetTransform.position - translationHelper.position).magnitude;
            float diff = newDist / startDist;
            float newScale = startScale * diff;
            TargetTransform.localScale = new Vector3(newScale, newScale, newScale);
        }
    }

    private Vector3 rotationUp;
    private bool wasRotating;
    private void UpdateRotating()
    {
        if(!wasRotating && PinchDetector.PinchBeginning)
        {
            translationHelper.position = PinchDetector.PinchPoint.position;
            rotationHelper.position = TargetTransform.position;
            rotationUp = TargetTransform.up;
            rotationHelper.LookAt(translationHelper, rotationUp);
            TargetTransform.SetParent(rotationHelper, true);
        }
        if(PinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();

            rotationHelper.LookAt(translationHelper, TargetTransform.up);
        }
        if(wasRotating && !PinchDetector.Pinching)
        {
            TargetTransform.SetParent(null, true);
        }
        wasRotating = PinchDetector.Pinching;
    }

    private Vector3 transformHelperStartPos;
    private Vector3 mainStageStartPos;
    private bool wasDragging;
    private void UpdateDragging()
    {
        if(!wasDragging && PinchDetector.PinchBeginning)
        {
            translationHelper.position = PinchDetector.PinchPoint.position;
            transformHelperStartPos = translationHelper.position;
            mainStageStartPos = TargetTransform.position;
        }
        if(PinchDetector.Pinching)
        {
            translationHelper.position = GetDeadzoneMovement();
            TargetTransform.position = mainStageStartPos + (translationHelper.position - transformHelperStartPos);
        }
        wasDragging = PinchDetector.Pinching;
    }
    
    private Vector3 GetDeadzoneMovement()
    {
        Vector3 toTarget = PinchDetector.PinchPoint.position - translationHelper.position;
        float distToTarget = toTarget.magnitude;
        float deadDist = Mathf.Max(0, distToTarget - Deadzone);
        return translationHelper.position + toTarget.normalized * deadDist;
    }
}
