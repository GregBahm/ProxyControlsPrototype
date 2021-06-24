using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ToolCursor : MonoBehaviour
{
    public Transform CursorStart;
    public Transform CursorMid;
    public Transform CursorEnd;

    [Range(0, .1f)]
    public float CursorWidth;

    public float IndicatorLength;

    public ProxyButton[] Buttons;
    public Transform RightFingerTip;

    private void Update()
    {
        ProxyButton focus = GetFocusedButton();
        UpdateCursor(focus);
    }

    private void UpdateCursor(ProxyButton focus)
    {
        CursorEnd.position = RightFingerTip.position;
        Vector3 target = focus == null ? RightFingerTip.position : focus.transform.position;
        CursorStart.position = Vector3.Lerp(CursorStart.position, target, Time.deltaTime * 20);
        CursorStart.localScale = new Vector3(CursorWidth, CursorWidth, CursorWidth);
        CursorEnd.localScale = CursorStart.localScale;
        PlaceCursorMid();
    }

    private void PlaceCursorMid()
    {
        CursorMid.position = (CursorStart.position + CursorEnd.position) / 2;
        CursorMid.LookAt(CursorStart);
        float length = (CursorStart.position - CursorEnd.position).magnitude / 2;
        CursorMid.localScale = new Vector3(CursorWidth, CursorWidth, length);
    }

    private ProxyButton GetFocusedButton()
    {
        float closest = IndicatorLength;
        ProxyButton ret = null;
        foreach (ProxyButton item in Buttons)
        {
            float dist = (item.transform.position - RightFingerTip.position).magnitude;
            if(dist < closest)
            {
                ret = item;
                closest = dist;
            }
        }
        return ret;
    }
}