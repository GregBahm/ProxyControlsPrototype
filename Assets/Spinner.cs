using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Spinner : MonoBehaviour
{
    public float SpinSpeed;
    void Update()
    {
        transform.Rotate(Vector3.up, SpinSpeed);
    }
}
