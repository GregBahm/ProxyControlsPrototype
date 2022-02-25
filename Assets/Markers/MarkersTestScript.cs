using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MarkersTestScript : MonoBehaviour
{
    public Transform MarkerPosition;
    public Transform TopContent;

    public Transform NorthPip;
    public Transform SouthPip;
    public Transform EastPip;
    public Transform WestPip;


    private void Update()
    {
        Shader.SetGlobalVector("_OrbPosition", MarkerPosition.position);
        PlaceTopContent();
        PlacePips();
    }

    private void PlaceTopContent()
    {
        TopContent.position = new Vector3(MarkerPosition.position.x, 0, MarkerPosition.position.z);
    }

    private void PlacePips()
    {
        Vector3 mPos = MarkerPosition.position;
        NorthPip.position = new Vector3(mPos.x, mPos.y, 1);
        SouthPip.position = new Vector3(mPos.x, mPos.y, -1);
        EastPip.position = new Vector3(1, mPos.y, mPos.z);
        WestPip.position = new Vector3(-1, mPos.y, mPos.z);
    }
}
