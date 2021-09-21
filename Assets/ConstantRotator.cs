using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ConstantRotator : MonoBehaviour
{
    [SerializeField]
    private float rotation;

    private void Update()
    {
        transform.Rotate(0, rotation * Time.deltaTime, 0);
    }
}