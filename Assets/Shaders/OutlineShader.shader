Shader "Custom/SimpleOutlineShader"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)
        [Header(Outline Settings)]
        _EnableOutline ("Enable Outline", Float) = 0
        _OutlineColor ("Outline Color", Color) = (0,1,1,1)
        _OutlineThickness ("Outline Thickness", Range(0,1)) = 0.5
        _OutlinePulse ("Outline Pulse Speed", Range(0,5)) = 1
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "CanUseSpriteAtlas"="True"
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
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            fixed4 _Color;
            // Outline properties
            float _EnableOutline;
            fixed4 _OutlineColor;
            float _OutlineThickness;
            float _OutlinePulse;
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
                
                if (_EnableOutline > 0.5)
                {
                    // Pulse multiplier
                    float pulse = 0.5 + 0.5 * abs(sin(_Time.y * _OutlinePulse));
                    
                    // Use texture texel size for accurate pixel sampling
                    float2 pixelSize = _MainTex_TexelSize.xy * _OutlineThickness * 10.0;
                    
                    // Sample the alpha of the current pixel
                    float currentAlpha = col.a;
                    
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
                return col;
            }
            ENDCG
        }
    }
}