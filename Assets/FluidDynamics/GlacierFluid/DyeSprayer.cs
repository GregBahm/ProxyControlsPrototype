using UnityEngine;

namespace Jules.FluidDynamics
{
    public class DyeSprayer : MonoBehaviour
    {
        [SerializeField]
        private Color color = Color.white;
        public Color Color => color;

        [SerializeField]
        private float radius = 10;
        public float Radius => radius;

        [SerializeField]
        private float force = 100;
        public float Force => force;
    }
}
