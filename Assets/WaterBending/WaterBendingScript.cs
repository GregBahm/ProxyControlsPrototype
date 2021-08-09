using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterBendingScript : MonoBehaviour
{
    [SerializeField]
    private int orbsCount;

    [SerializeField]
    private GameObject orbPrefab;

    [SerializeField]
    private float maxSizeVelocity;

    [SerializeField]
    private float minOrbSize;

    [SerializeField]
    private float maxOrbSize;

    [SerializeField]
    private float orbSizeDistribution;

    [SerializeField]
    private float velocityDecayMin;

    [SerializeField]
    private float velocityDecayMax;

    [SerializeField]
    private float velocityDecayDistribution;

    [SerializeField]
    private float dampMin;

    [SerializeField]
    private float dampMax;

    [SerializeField]
    private float dampDistribution;

    private WaterBendingOrb[] orbs;

    private void Start()
    {
        orbs = CreateOrbs();
    }

    private WaterBendingOrb[] CreateOrbs()
    {
        List<WaterBendingOrb> ret = new List<WaterBendingOrb>();
        for (int i = 0; i < orbsCount; i++)
        {
            GameObject newObj = Instantiate(orbPrefab);
            float sizeParam = (float)i / orbsCount;
            WaterBendingOrb newOrb = new WaterBendingOrb(this, sizeParam, newObj.transform);
            ret.Add(newOrb);
        }
        return ret.ToArray();
    }

    private void Update()
    {
        Vector3 handPos = Hands.Instance.LeftHandProxy.MiddleProximal.position;
        Shader.SetGlobalVector("_OrbFocusPoint", handPos);
        foreach (WaterBendingOrb orb in orbs)
        {
            orb.Update(handPos);
        }
    }

    class WaterBendingOrb
    {
        private readonly WaterBendingScript mothership;
        private readonly float sizeParam;
        private readonly Transform transform;

        public float Size
        {
            get
            {
                float param = Mathf.Pow(sizeParam, mothership.orbSizeDistribution);
                return Mathf.Lerp(mothership.minOrbSize, mothership.maxOrbSize, param);
            }
        }
        public float VelocityDecay
        {
            get
            {
                float param = Mathf.Pow(sizeParam, mothership.velocityDecayDistribution);
                return Mathf.Lerp(mothership.velocityDecayMin, mothership.velocityDecayMax, param);
            }
        }
        public float Damp
        {
            get
            {
                float param = Mathf.Pow(sizeParam, mothership.dampDistribution);
                return Mathf.Lerp(mothership.dampMin, mothership.dampMax, param);
            }
        }

        private Vector3 velocity;

        public WaterBendingOrb(WaterBendingScript mothership, float sizeParam, Transform transform)
        {
            this.mothership = mothership;
            this.sizeParam = sizeParam;
            this.transform = transform;
        }

        private Vector3 lastHandPos;

        public void Update(Vector3 handPos)
        {
            Vector3 handChange = handPos - lastHandPos;
            lastHandPos = handPos;

            Vector3 toTarget = handPos - transform.position;
            velocity += handChange;
            velocity += toTarget * Damp;
            velocity *= VelocityDecay;
            transform.position += velocity;
            transform.localScale = new Vector3(Size, Size, Size);
        }
    }

}
