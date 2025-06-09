// Shaders.metal

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord; // 텍스처 좌표 대신 정점 좌표를 활용할 수 있음
};

// 유니폼 데이터: Swift 코드에서 전달받을 값
struct Uniforms {
    float pitch; // 기기의 pitch 값
    float roll;  // 기기의 roll 값
    float2 resolution; // 뷰의 해상도 (버튼 크기)
};

vertex VertexOut
vertex_shader(uint vertexID [[vertex_id]],
              constant float2 *positions [[buffer(0)]]) {
    VertexOut out;
    // 간단한 사각형을 위한 정점 좌표 (화면 중앙에 위치)
    // 실제로는 버튼의 크기와 위치에 맞게 조정 필요
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.texCoord = positions[vertexID] * 0.5 + 0.5; // 0~1 범위로 정규화 (셰이더 내에서 활용)
    return out;
}

fragment half4 fragment_shader(VertexOut in [[stage_in]],
                                constant Uniforms &uniforms [[buffer(0)]]) {
    half3 baseColor = half3(0.3, 0.6, 0.9); // 버튼의 기본 색상 (파란색 계열)

    // 빛의 방향을 pitch와 roll 값으로 시뮬레이션
    // Y축은 화면 위쪽이 양수, X축은 오른쪽이 양수라고 가정
    // roll은 Y축 회전(좌우 기울기), pitch는 X축 회전(앞뒤 기울기)에 해당
    // 빛의 방향 벡터 (정규화)
    // Z값은 화면에서 나오는 방향을 양수로 가정하고, 빛이 약간 위에서 비춘다고 설정
    float3 lightDirection = normalize(float3(uniforms.roll, -uniforms.pitch, 0.5));


    // 표면 법선 벡터 (여기서는 간단히 화면을 향하는 방향으로 가정)
    float3 normal = float3(0.0, 0.0, 1.0);

    // 확산광(Diffuse Light) 계산
    float diffuseFactor = max(0.0, dot(normal, lightDirection));

    // "오묘한" 느낌을 위한 추가 효과: 가장자리 하이라이트 (간단 버전)
    // 화면 중앙으로부터의 거리를 기반으로 가장자리 감지
    float2 center = float2(0.0, 0.0); // 정점 좌표계의 중앙
    float dist = distance( in.texCoord * 2.0 - 1.0, center); // -1 ~ 1 범위로 변환 후 중앙과의 거리
    float edgeHighlight = smoothstep(0.7, 1.0, dist) * 0.5; // 가장자리에 가까울수록 밝아짐

    // 최종 색상 계산
    half3 litColor = baseColor * (diffuseFactor + 0.2) + edgeHighlight * diffuseFactor; // 주변광(0.2) 추가 및 가장자리 하이라이트

    return half4(litColor, 1.0);
}
