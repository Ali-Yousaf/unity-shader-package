Shader "Custom/SimpleFadeShader"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        [Header(Fade Settings)]
        _FadeColor ("Fade Color", Color) = (1,1,1,1)
        _FadeSpeed ("Fade Speed", Range(0.1, 5)) = 1

        [Enum(FadeIn,0,FadeInAndOut,1)]
        _FadeMode ("Fade Mode", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
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
            fixed4 _Color;
            fixed4 _FadeColor;
            float _FadeSpeed;
            float _FadeMode;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color * _Color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;

                float fade;

                // Fade In only
                if (_FadeMode == 0)
                {
                    fade = saturate(_Time.y * _FadeSpeed);
                }
                // Fade In & Fade Out
                else
                {
                    fade = abs(sin(_Time.y * _FadeSpeed));
                }

                // Apply alpha
                col.a *= fade;

                // Fade color blend
                col.rgb = lerp(_FadeColor.rgb, col.rgb, fade);

                return col;
            }
            ENDCG
        }
    }
}
