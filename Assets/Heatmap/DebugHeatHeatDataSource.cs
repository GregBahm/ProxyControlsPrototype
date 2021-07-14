using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(HeatMapHexController))]
public class DebugHeatHeatDataSource : MonoBehaviour
{
    [SerializeField]
    private Transform[] HeatProxies;

    [SerializeField]
    private BoxCollider mapTransform;

    private HeatMapHexController _controller;

    private void Start()
    {
        _controller = GetComponent<HeatMapHexController>();
    }

    private void Update()
    {
        HeatMapHexController.HeatData[] data = new HeatMapHexController.HeatData[HeatProxies.Length];
        for (int i = 0; i < HeatProxies.Length; i++)
        {
            Transform proxy = HeatProxies[i];
            Vector3 localPos = mapTransform.transform.InverseTransformPoint(proxy.position);
            data[i].Position = new Vector2(localPos.x + .5f, localPos.z + .5f);
            data[i].Intensity = Mathf.Clamp01(localPos.y) + .5f;
        }
        _controller.SetHeatData(data);
    }
}
