using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DyeSprayer : MonoBehaviour
{

    [SerializeField]
    private Color color = Color.white;

    [SerializeField]
    private float radius = 2;

    [SerializeField]
    private float force = 100;

    [SerializeField]
    private FluidSimulator simulator;

	void Update ()
    {
        simulator.SprayDye(transform.localPosition, transform.forward * force, radius, color);
	}
}
