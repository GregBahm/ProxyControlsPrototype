using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Orca : MonoBehaviour
{
    public Transform Joint1;
    public Transform Joint2;
    public Transform Joint3;
    public Transform Joint4;
    public Transform Joint5;
    public Transform Joint6;

    public Transform[] Joints { get; private set; }

    private void Awake()
    {
        Joints = new Transform[] { Joint1, Joint2, Joint3, Joint4, Joint5, Joint6 };
    }
}
