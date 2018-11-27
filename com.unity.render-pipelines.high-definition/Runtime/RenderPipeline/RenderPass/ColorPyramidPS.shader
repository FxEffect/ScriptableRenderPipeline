Shader "ColorPyramidPS"
{
    HLSLINCLUDE

        #pragma target 4.5
        #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"

        TEXTURE2D(_Source);
        SamplerState sampler_LinearClamp;
        uniform float4 _SrcScaleBias;
        uniform float4 _SrcUvLimits; // {xy: max uv, zw: direction of blurfor 1 texel }
        uniform float _SourceMip;

        struct Attributes
        {
            uint vertexID : SV_VertexID;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord   : TEXCOORD0;
        };

        Varyings Vert(Attributes input)
        {
            Varyings output;
            output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
            output.texcoord   = GetFullScreenTriangleTexCoord(input.vertexID) * _SrcScaleBias.xy + _SrcScaleBias.zw;
            return output;
        }

        float4 FragBilinear(Varyings input) : SV_Target
        {
            // Gaussian weights for 9 texel kernel from center textel to furthest texel. Keep in sync with ColorPyramid.compute
            const float gaussWeights[] = { 0.27343750, 0.21875000, 0.10937500, 0.03125000, 0.00390625 };

            float2 offset = _SrcUvLimits.zw;
            float2 offset1 = offset * (1.0 + (gaussWeights[2] / (gaussWeights[1] + gaussWeights[2])));
            float2 offset2 = offset * (3.0 + (gaussWeights[4] / (gaussWeights[3] + gaussWeights[4])));

            float2 uv_m2 = input.texcoord.xy - offset2;
            float2 uv_m1 = input.texcoord.xy - offset1;
            float2 uv_p0 = input.texcoord.xy;
            float2 uv_p1 = min(_SrcUvLimits.xy, input.texcoord.xy + offset1);
            float2 uv_p2 = min(_SrcUvLimits.xy, input.texcoord.xy + offset2);

            return
              + SAMPLE_TEXTURE2D_LOD(_Source, sampler_LinearClamp, uv_m2, _SourceMip) * (gaussWeights[3] + gaussWeights[4])
              + SAMPLE_TEXTURE2D_LOD(_Source, sampler_LinearClamp, uv_m1, _SourceMip) * (gaussWeights[1] + gaussWeights[2])
              + SAMPLE_TEXTURE2D_LOD(_Source, sampler_LinearClamp, uv_p0, _SourceMip) *  gaussWeights[0]
              + SAMPLE_TEXTURE2D_LOD(_Source, sampler_LinearClamp, uv_p1, _SourceMip) * (gaussWeights[1] + gaussWeights[2])
              + SAMPLE_TEXTURE2D_LOD(_Source, sampler_LinearClamp, uv_p2, _SourceMip) * (gaussWeights[3] + gaussWeights[4]);
        }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }

        // 0: Bilinear tri
        Pass
        {
            ZWrite Off ZTest Always Blend Off Cull Off

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragBilinear
            ENDHLSL
        }

    }

    Fallback Off
}
