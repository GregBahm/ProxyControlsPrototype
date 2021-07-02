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
    public TMPro.TextMeshPro Icon;

    private string baseIconGlyph;
    public string ToggledIconGlyph;

    private void Start()
    {
        baseIconGlyph = Icon.text;
        button = GetComponent<ProxyButton>();
        mat = GetComponent<MeshRenderer>().material;
    }

    void Update()
    {
        UpdateIconGlyph();

        mat.color = GetMatColor();
        Icon.transform.LookAt(Camera.main.transform, Vector3.up);
        Icon.transform.Rotate(0, 180, 0, Space.Self);
    }

    private void UpdateIconGlyph()
    {
        if (string.IsNullOrEmpty(ToggledIconGlyph))
            return;

        Icon.text = button.Toggled ? ToggledIconGlyph : baseIconGlyph;
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
