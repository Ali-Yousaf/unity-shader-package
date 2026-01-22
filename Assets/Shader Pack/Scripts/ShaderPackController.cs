using UnityEngine;
using UnityEngine.UI;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteAlways]
public class AllIn1ShaderController : MonoBehaviour
{
    [Header("Enable Effects")]
    public bool enableGlow = false;
    public bool enableFade = false;
    public bool enableFlash = false;
    public bool enableShake = false;
    public bool enableOutline = false;

    [Header("Glow Settings")]
    public Color glowColor = Color.yellow;
    [Range(0, 10)] public float glowIntensity = 1;
    [Range(0.01f, 0.1f)] public float glowSize = 0.02f;
    [Range(0.1f, 5f)] public float blinkSpeed = 1f;
    [Range(0f, 1f)] public float blinkMin = 0.3f;

    [Header("Fade Settings")]
    public Color fadeColor = Color.white;
    [Range(0.1f, 5f)] public float fadeSpeed = 1f;
    [Range(0f, 1f)] public float fadeMode = 0f; // 0 = Fade In, 1 = Fade In & Out

    [Header("Flash Settings")]
    public Color flashColor = Color.red;
    [Range(0f, 1f)] public float flashStrength = 1f;
    [Range(0.1f, 20f)] public float flashSpeed = 10f;
    public KeyCode flashKey = KeyCode.F;

    [Header("Shake Settings")]
    [Range(0f, 1f)] public float shakeIntensity = 0.1f;
    [Range(0.1f, 50f)] public float shakeFrequency = 10f;
    [Range(0f, 5f)] public float shakeDuration = 0f;

    [Header("Outline Settings")]
    public Color outlineColor = Color.cyan;
    [Range(0f, 1f)] public float outlineThickness = 0.5f;
    [Range(0f, 5f)] public float outlinePulse = 1f;

    private Material _materialInstance;
    private SpriteRenderer _spriteRenderer;
    private Image _uiImage;

    private Vector3 _originalPosition;
    private float _shakeTime = 0f;

    private void Awake()
    {
        _spriteRenderer = GetComponent<SpriteRenderer>();
        _uiImage = GetComponent<Image>();

        // Save original position
        if (_spriteRenderer != null)
            _originalPosition = _spriteRenderer.transform.localPosition;
        else if (_uiImage != null)
            _originalPosition = _uiImage.transform.localPosition;

        // Use sharedMaterial in Edit Mode, instance in Play Mode
        if (_spriteRenderer != null)
            _materialInstance = Application.isPlaying ? _spriteRenderer.material : _spriteRenderer.sharedMaterial;
        else if (_uiImage != null)
            _materialInstance = _uiImage.material;
    }

    private void Update()
    {
        if (_materialInstance == null) return;

        // Assign material
        if (_spriteRenderer != null)
            _spriteRenderer.material = _materialInstance;
        if (_uiImage != null)
            _uiImage.material = _materialInstance;

        // Glow
        _materialInstance.SetFloat("_EnableGlow", enableGlow ? 1f : 0f);
        if (enableGlow)
        {
            _materialInstance.SetColor("_GlowColor", glowColor);
            _materialInstance.SetFloat("_GlowIntensity", glowIntensity);
            _materialInstance.SetFloat("_GlowSize", glowSize);
            _materialInstance.SetFloat("_BlinkSpeed", blinkSpeed);
            _materialInstance.SetFloat("_BlinkMin", blinkMin);
        }

        // Fade
        _materialInstance.SetFloat("_EnableFade", enableFade ? 1f : 0f);
        if (enableFade)
        {
            _materialInstance.SetColor("_FadeColor", fadeColor);
            _materialInstance.SetFloat("_FadeSpeed", fadeSpeed);
            _materialInstance.SetFloat("_FadeMode", fadeMode);
        }

        // Flash
        _materialInstance.SetFloat("_EnableFlash", enableFlash ? 1f : 0f);
        _materialInstance.SetColor("_FlashColor", flashColor);
        _materialInstance.SetFloat("_FlashStrength", flashStrength);
        _materialInstance.SetFloat("_FlashSpeed", flashSpeed);

        // Flash key input
        if (enableFlash && Application.isPlaying && Input.GetKeyDown(flashKey))
            TriggerFlash();

        // Shake
        if (enableShake)
        {
            if (shakeDuration > 0f)
            {
                _shakeTime -= Time.deltaTime;
                if (_shakeTime <= 0f)
                {
                    _shakeTime = 0f;
                    ResetPosition();
                }
            }

            if (_shakeTime > 0f || shakeDuration == 0f)
            {
                Vector3 offset = new Vector3(
                    (Mathf.PerlinNoise(Time.time * shakeFrequency, 0f) - 0.5f) * 2f * shakeIntensity,
                    (Mathf.PerlinNoise(0f, Time.time * shakeFrequency) - 0.5f) * 2f * shakeIntensity,
                    0f
                );

                if (_spriteRenderer != null)
                    _spriteRenderer.transform.localPosition = _originalPosition + offset;
                if (_uiImage != null)
                    _uiImage.transform.localPosition = _originalPosition + offset;
            }
        }
        else
        {
            ResetPosition();
        }

        // Outline
        _materialInstance.SetFloat("_EnableOutline", enableOutline ? 1f : 0f);
        if (enableOutline)
        {
            _materialInstance.SetColor("_OutlineColor", outlineColor);
            _materialInstance.SetFloat("_OutlineThickness", outlineThickness);
            _materialInstance.SetFloat("_OutlinePulse", outlinePulse);
        }
    }

    public void TriggerFlash(float strength = 1f)
    {
        if (!enableFlash || _materialInstance == null) return;
        _materialInstance.SetFloat("_TriggerFlash", strength);
    }

    public void TriggerShake(float duration)
    {
        if (!enableShake) return;
        _shakeTime = duration;
    }

    private void ResetPosition()
    {
        if (_spriteRenderer != null)
            _spriteRenderer.transform.localPosition = _originalPosition;
        if (_uiImage != null)
            _uiImage.transform.localPosition = _originalPosition;
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(AllIn1ShaderController))]
public class AllIn1ShaderControllerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        var controller = (AllIn1ShaderController)target;

        EditorGUILayout.LabelField("All-in-1 Shader Effects", EditorStyles.boldLabel);

        // Glow
        controller.enableGlow = EditorGUILayout.Toggle("Glow", controller.enableGlow);
        if (controller.enableGlow)
        {
            controller.glowColor = EditorGUILayout.ColorField("Glow Color", controller.glowColor);
            controller.glowIntensity = EditorGUILayout.Slider("Glow Intensity", controller.glowIntensity, 0, 10);
            controller.glowSize = EditorGUILayout.Slider("Glow Size", controller.glowSize, 0.01f, 0.1f);
            controller.blinkSpeed = EditorGUILayout.Slider("Blink Speed", controller.blinkSpeed, 0.1f, 5f);
            controller.blinkMin = EditorGUILayout.Slider("Blink Min", controller.blinkMin, 0f, 1f);
        }

        // Fade
        controller.enableFade = EditorGUILayout.Toggle("Fade", controller.enableFade);
        if (controller.enableFade)
        {
            controller.fadeColor = EditorGUILayout.ColorField("Fade Color", controller.fadeColor);
            controller.fadeSpeed = EditorGUILayout.Slider("Fade Speed", controller.fadeSpeed, 0.1f, 5f);
            controller.fadeMode = EditorGUILayout.Slider("Fade Mode", controller.fadeMode, 0f, 1f);
        }

        // Flash
        controller.enableFlash = EditorGUILayout.Toggle("Flash", controller.enableFlash);
        if (controller.enableFlash)
        {
            controller.flashColor = EditorGUILayout.ColorField("Flash Color", controller.flashColor);
            controller.flashStrength = EditorGUILayout.Slider("Flash Strength", controller.flashStrength, 0f, 1f);
            controller.flashSpeed = EditorGUILayout.Slider("Flash Speed", controller.flashSpeed, 0.1f, 20f);
            controller.flashKey = (KeyCode)EditorGUILayout.EnumPopup("Flash Key", controller.flashKey);

            if (GUILayout.Button("Trigger Flash"))
                controller.TriggerFlash();
        }

        // Shake
        controller.enableShake = EditorGUILayout.Toggle("Shake", controller.enableShake);
        if (controller.enableShake)
        {
            controller.shakeIntensity = EditorGUILayout.Slider("Shake Intensity", controller.shakeIntensity, 0f, 1f);
            controller.shakeFrequency = EditorGUILayout.Slider("Shake Frequency", controller.shakeFrequency, 0.1f, 50f);
            controller.shakeDuration = EditorGUILayout.Slider("Shake Duration", controller.shakeDuration, 0f, 5f);

            if (GUILayout.Button("Trigger Shake"))
                controller.TriggerShake(controller.shakeDuration);
        }

        // Outline
        controller.enableOutline = EditorGUILayout.Toggle("Outline", controller.enableOutline);
        if (controller.enableOutline)
        {
            controller.outlineColor = EditorGUILayout.ColorField("Outline Color", controller.outlineColor);
            controller.outlineThickness = EditorGUILayout.Slider("Outline Thickness", controller.outlineThickness, 0f, 1f);
            controller.outlinePulse = EditorGUILayout.Slider("Outline Pulse", controller.outlinePulse, 0f, 5f);
        }

        serializedObject.ApplyModifiedProperties();
    }
}
#endif