using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DyeSprayRattler : MonoBehaviour
{
    public float DriftIntensity;
    public float DriftReversion;

    private void Update()
    {
        Vector2 rand = UnityEngine.Random.insideUnitCircle;
        Vector3 randNormal = new Vector3(rand.x, -1, rand.y).normalized;
        transform.forward = Vector3.Lerp(transform.forward, randNormal, DriftIntensity);
        transform.forward = Vector3.Lerp(transform.forward, transform.parent.forward, DriftReversion);
    }
}
