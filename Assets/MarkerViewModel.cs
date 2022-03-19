using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MarkerViewModel : MonoBehaviour
{
    public Material MarkerSelectionOrbMat;
    public Material WaterPlaneMat;
    public Material OceanFloorMat;

    private Vector3 lastPos;
    public float DirectionUpdateMin;
    public Transform OrbTransform;
    public Transform RotationContent;
    public Transform BillboardContent;
    private Vector3 targetRotation;

    public Transform NorthPip;
    public Transform SouthPip;
    public Transform EastPip;
    public Transform WestPip;

    private void Update()
    {
        SetMaterialProperties();
        SetMarkerDirection();
        SetBillboardContent();
        PlacePips();
    }

    private void SetBillboardContent()
    {
        Vector3 cameraPos = Camera.main.transform.position;
        cameraPos.y = BillboardContent.position.y;
        BillboardContent.forward = cameraPos - BillboardContent.position;
    }

    private void SetMarkerDirection()
    {
        Vector3 toLastPos = lastPos - OrbTransform.position;
        toLastPos.y = 0;
        if (toLastPos.magnitude > DirectionUpdateMin)
        {
            targetRotation = toLastPos.normalized;
            lastPos = OrbTransform.position;
        }
        RotationContent.forward = Vector3.Lerp(RotationContent.forward, targetRotation, Time.deltaTime * 15);
    }

    private void SetMaterialProperties()
    {
        MarkerSelectionOrbMat.SetFloat("_WaterLevel", OrbTransform.position.y);
        WaterPlaneMat.SetVector("_OrbPosition", OrbTransform.position);
        WaterPlaneMat.SetFloat("_OrbSize", OrbTransform.lossyScale.x * .5f);

        OceanFloorMat.SetVector("_OrbPosition", OrbTransform.position);
        OceanFloorMat.SetFloat("_OrbSize", OrbTransform.lossyScale.x * .5f);
    }
    private void PlacePips()
    {
        Vector3 mPos = OrbTransform.position;
        NorthPip.position = new Vector3(mPos.x, mPos.y, 1);
        SouthPip.position = new Vector3(mPos.x, mPos.y, -1);
        EastPip.position = new Vector3(1, mPos.y, mPos.z);
        WestPip.position = new Vector3(-1, mPos.y, mPos.z);
    }
}
