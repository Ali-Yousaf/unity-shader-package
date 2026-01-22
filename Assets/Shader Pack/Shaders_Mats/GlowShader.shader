Shader "Custom/SimpleGlowShader"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint Color", Color) = (1, 1, 1, 1)
        
        [Header(Glow Settings)]
        _GlowColor ("Glow Color", Color) = (1, 1, 0, 1)
        _GlowIntensity ("Glow Intensity", Range(0, 10)) = 5.7
        _GlowSize ("Glow Size", Range(0, 0.1)) = 0.02
        
        [Header(Blink Settings)]
        _BlinkSpeed ("Blink Speed", Range(0.1, 5)) = 1.0
        _BlinkMin ("Blink Minimum", Range(0, 1)) = 0.3
    }
    
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "CanUseSpriteAtlas" = "True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _GlowColor;
            float _GlowIntensity;
            float _GlowSize;
            float _BlinkSpeed;
            float _BlinkMin;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.texcoord = TRANSFORM_TEX(IN.texcoord, _MainTex);
                OUT.color = IN.color * _Color;
                UNITY_TRANSFER_FOG(OUT, OUT.vertex);
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 tex = tex2D(_MainTex, IN.texcoord);
                fixed4 col = tex * IN.color;

                // Calculate blink effect using sine wave
                float blink = sin(_Time.y * _BlinkSpeed * 3.14159) * 0.5 + 0.5;
                blink = lerp(_BlinkMin, 1.0, blink);

                // Sample neighboring pixels for glow effect
                float2 pixelSize = _GlowSize / float2(1280, 720); // Adjust based on screen res
                
                fixed4 glowSample = fixed4(0, 0, 0, 0);
                
                // Sample 8 directions around the pixel
                glowSample += tex2D(_MainTex, IN.texcoord + float2(pixelSize.x, 0));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(-pixelSize.x, 0));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(0, pixelSize.y));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(0, -pixelSize.y));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(pixelSize.x, pixelSize.y));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(-pixelSize.x, pixelSize.y));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(pixelSize.x, -pixelSize.y));
                glowSample += tex2D(_MainTex, IN.texcoord + float2(-pixelSize.x, -pixelSize.y));
                
                glowSample /= 8.0;
                
                // Add glow effect with blink
                fixed4 glow = glowSample * _GlowColor * _GlowIntensity * blink;
                
                // Combine original color with glow
                col.rgb += glow.rgb * glow.a;
                
                UNITY_APPLY_FOG(IN.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}