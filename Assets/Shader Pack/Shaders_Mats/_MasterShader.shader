Shader "Custom/MasterAllIn1"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        [Header(Glow Settings)]
        _EnableGlow ("Enable Glow", Float) = 0
        _GlowColor ("Glow Color", Color) = (1,1,0,1)
        _GlowIntensity ("Glow Intensity", Range(0,10)) = 5.7
        _GlowSize ("Glow Size", Range(0,0.1)) = 0.02
        _BlinkSpeed ("Blink Speed", Range(0.1,5)) = 1
        _BlinkMin ("Blink Minimum", Range(0,1)) = 0.3

        [Header(Fade Settings)]
        _EnableFade ("Enable Fade", Float) = 0
        _FadeColor ("Fade Color", Color) = (1,1,1,1)
        _FadeSpeed ("Fade Speed", Range(0.1,5)) = 1
        _FadeMode ("Fade Mode (0=In,1=InOut)", Float) = 0

        [Header(Flash Settings)]
        _EnableFlash ("Enable Flash", Float) = 0
        _FlashColor ("Flash Color", Color) = (1,0,0,1)
        _FlashStrength ("Flash Strength", Range(0,1)) = 1
        _FlashSpeed ("Flash Duration", Range(0.1,20)) = 10
        _TriggerFlash ("Trigger Flash", Range(0,1)) = 0

        [Header(Outline Settings)]
        _EnableOutline ("Enable Outline", Float) = 0
        _OutlineColor ("Outline Color", Color) = (0,1,1,1)
        _OutlineThickness ("Outline Thickness", Range(0,1)) = 0.5
        _OutlinePulse ("Outline Pulse", Range(0,5)) = 1
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" "CanUseSpriteAtlas"="True" }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata { float4 vertex : POSITION; float4 color : COLOR; float2 uv : TEXCOORD0; };
            struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; fixed4 color : COLOR; };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            fixed4 _Color;

            // Glow
            float _EnableGlow; fixed4 _GlowColor; float _GlowIntensity; float _GlowSize; float _BlinkSpeed; float _BlinkMin;

            // Fade
            float _EnableFade; fixed4 _FadeColor; float _FadeSpeed; float _FadeMode;

            // Flash
            float _EnableFlash; fixed4 _FlashColor; float _FlashStrength; float _FlashSpeed; float _TriggerFlash;

            // Outline
            float _EnableOutline; fixed4 _OutlineColor; float _OutlineThickness; float _OutlinePulse;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color * _Color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;

                // ==================
                // Outline (Apply BEFORE other effects so it's visible)
                // ==================
                if (_EnableOutline > 0.5)
                {
                    float pulse = 0.5 + 0.5 * abs(sin(_Time.y * _OutlinePulse));
                    
                    // Use texture texel size for accurate pixel sampling
                    float2 pixelSize = _MainTex_TexelSize.xy * _OutlineThickness * 10.0;
                    
                    // Sample the alpha of the current pixel
                    float currentAlpha = tex2D(_MainTex, i.uv).a;
                    
                    // Sample neighboring pixels and find max alpha
                    float maxNeighborAlpha = 0.0;
                    
                    // 8-directional sampling
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(pixelSize.x, 0)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(-pixelSize.x, 0)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(0, pixelSize.y)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(0, -pixelSize.y)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(pixelSize.x, pixelSize.y)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(-pixelSize.x, pixelSize.y)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(pixelSize.x, -pixelSize.y)).a);
                    maxNeighborAlpha = max(maxNeighborAlpha, tex2D(_MainTex, i.uv + float2(-pixelSize.x, -pixelSize.y)).a);
                    
                    // Calculate outline: visible where neighbors have alpha but current pixel doesn't
                    float outlineAlpha = saturate(maxNeighborAlpha - currentAlpha) * pulse;
                    
                    // Blend outline color
                    col.rgb = lerp(col.rgb, _OutlineColor.rgb, outlineAlpha);
                    col.a = max(col.a, outlineAlpha);
                }

                // ==================
                // Glow
                // ==================
                if (_EnableGlow > 0.5)
                {
                    float blink = sin(_Time.y * _BlinkSpeed * 3.14159) * 0.5 + 0.5;
                    blink = lerp(_BlinkMin, 1.0, blink);
                    float2 pixelSize = _GlowSize / float2(1280, 720);
                    fixed4 glowSample = fixed4(0,0,0,0);
                    glowSample += tex2D(_MainTex, i.uv + float2(pixelSize.x,0));
                    glowSample += tex2D(_MainTex, i.uv + float2(-pixelSize.x,0));
                    glowSample += tex2D(_MainTex, i.uv + float2(0,pixelSize.y));
                    glowSample += tex2D(_MainTex, i.uv + float2(0,-pixelSize.y));
                    glowSample += tex2D(_MainTex, i.uv + float2(pixelSize.x,pixelSize.y));
                    glowSample += tex2D(_MainTex, i.uv + float2(-pixelSize.x,pixelSize.y));
                    glowSample += tex2D(_MainTex, i.uv + float2(pixelSize.x,-pixelSize.y));
                    glowSample += tex2D(_MainTex, i.uv + float2(-pixelSize.x,-pixelSize.y));
                    glowSample /= 8.0;
                    fixed4 glow = glowSample * _GlowColor * _GlowIntensity * blink;
                    col.rgb += glow.rgb * glow.a;
                }

                // ==================
                // Fade
                // ==================
                if (_EnableFade > 0.5)
                {
                    float fade = _FadeMode < 0.5 ? saturate(_Time.y * _FadeSpeed) : abs(sin(_Time.y * _FadeSpeed));
                    col.a *= fade;
                    col.rgb = lerp(_FadeColor.rgb, col.rgb, fade);
                }

                // ==================
                // Flash
                // ==================
                if (_EnableFlash > 0.5 && _TriggerFlash > 0.01)
                {
                    float flashDuration = 1.0 / _FlashSpeed;
                    float t = fmod(_Time.y, flashDuration);
                    float flash = saturate(1.0 - t / flashDuration) * _FlashStrength * _TriggerFlash;
                    col.rgb = lerp(col.rgb, _FlashColor.rgb, flash);
                }

                return col;
            }
            ENDCG
        }
    }
}