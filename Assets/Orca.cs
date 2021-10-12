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
    public Pose[] OriginalLocalPoses { get; private set; }
    private void Awake()
    {
        Joints = new Transform[] { Joint1, Joint2, Joint3, Joint4, Joint5, Joint6 };

        OriginalLocalPoses = new Pose[] {
            new Pose(Joint1.localPosition, Joint1.localRotation),
            new Pose(Joint2.localPosition, Joint2.localRotation),
            new Pose(Joint3.localPosition, Joint3.localRotation),
            new Pose(Joint4.localPosition, Joint4.localRotation),
            new Pose(Joint5.localPosition, Joint5.localRotation),
            new Pose(Joint6.localPosition, Joint6.localRotation) };

    }
}
