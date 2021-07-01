using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DirectionTesterScript : MonoBehaviour
{
    public Transform DirectionTesterControl;
    public Material Mat;
    public Vector3 NewForward;

    private void Update()
    {
        Mat.SetVector("_Direction", DirectionTesterControl.forward);
    }
}
