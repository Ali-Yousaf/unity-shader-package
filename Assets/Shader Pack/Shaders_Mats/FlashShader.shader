Shader "Custom/ManualFlashShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1,1,1,1)

        [Header(Flash Settings)]
        _FlashColor ("Flash Color", Color) = (1,0,0,1)
        _FlashStrength ("Flash Strength", Range(0,1)) = 1
        _FlashSpeed ("Flash Duration", Range(0.1,5)) = 2
        _TriggerFlash ("Trigger Flash", Range(0,1)) = 0
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
            fixed4 _Color;
            fixed4 _FlashColor;
            float _FlashStrength;
            float _FlashSpeed;
            float _TriggerFlash;

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

                // Flash effect
                float flash = 0;

                if (_TriggerFlash > 0)
                {
                    flash = saturate(1.0 - (_Time.y * _FlashSpeed));
                    flash *= _FlashStrength;
                    flash = flash * _TriggerFlash;
                }

                col.rgb = lerp(col.rgb, _FlashColor.rgb, flash);

                return col;
            }
            ENDCG
        }
    }
}
