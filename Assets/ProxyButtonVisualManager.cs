using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(ProxyButton))]
public class ProxyButtonVisualManager : MonoBehaviour
{
    public Color PressedColor;
    public Color ToggledColor;
    public Color RegularColor;

    private ProxyButton button;
    private Material mat;
    public Transform Icon;

    private void Start()
    {
        button = GetComponent<ProxyButton>();
        mat = GetComponent<MeshRenderer>().material;
    }

    void Update()
    {
        mat.color = GetMatColor();
        Icon.LookAt(Camera.main.transform, Vector3.up);
        Icon.Rotate(0, 180, 0, Space.Self);
    }

    private Color GetMatColor()
    {
        if (button.State == ProxyButton.ButtonState.Pressed)
            return PressedColor;
        if (button.Toggled)
            return ToggledColor;
        return RegularColor;
    }
}
