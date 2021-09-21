using UnityEngine;

public class Waypoint : MonoBehaviour
{
    [SerializeField]
    private Transform weightHandle;

    public float Weight { get { return weightHandle.localPosition.z; } }

    public void Set(Vector3 position, Quaternion rotation, float weight)
    {
        transform.position = position;
        transform.rotation = rotation;
        weightHandle.localPosition = new Vector3(0, 0, weight);
    }
}
