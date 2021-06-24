using System;
using UnityEngine;

public class ProxyButton : MonoBehaviour
{
    public enum ButtonState
    {
        Disabled,
        Ready,
        Pressed
    }

    [SerializeField]
    private ButtonInteractionStyles interactionStyle;
    public ButtonInteractionStyles InteractionStyle => interactionStyle;

    [SerializeField]
    private bool toggled;
    public bool Toggled { get => toggled; set => toggled = value; }

    private ButtonState oldState;
    public ButtonState State { get; private set; }

    public event EventHandler Clicked;

#if UNITY_EDITOR
    [SerializeField]
    private bool testClick;
#endif

    private void Start()
    {
        State = ButtonState.Ready;
    }

    private void Update()
    {
#if UNITY_EDITOR
        if (testClick)
        {
            testClick = false;
            OnClicked();
        }
#endif
        State = UpdateState();
        if (State == ButtonState.Pressed && oldState != ButtonState.Pressed)
        {
            OnClicked();
        }
        oldState = State;
    }

    private void OnClicked()
    {
        if (interactionStyle == ButtonInteractionStyles.ToggleButton)
        {
            Toggled = !Toggled;
        }
        EventHandler handler = Clicked;
        handler?.Invoke(this, EventArgs.Empty);
    }

    private ButtonState UpdateState()
    {
        Vector3 fingerPos = Hands.Instance.RightHandProxy.IndexTip.position;
        float dist = (transform.position - fingerPos).magnitude * 2;
        bool pressed = dist < transform.lossyScale.x;
        if (pressed)
        {
            return ButtonState.Pressed;
        }

        return ButtonState.Ready;
    }

    public enum ButtonInteractionStyles
    {
        ToggleButton,
        ClickButton
    }
}
