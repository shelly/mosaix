//
//  TenPointAveraging.metal
//  Mosaix
//
//  Created by Nathan Eliason on 4/19/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


// Thread ID == (thread position in thread group)  +    (thread group position in grid * threads per thread group)

kernel void findNinePointAverage(
    texture2d image [[ texture(0) ]],
    device float* result [[ buffer(0) ]],
    uint gridSize [[ buffer[1] ]],
    uint threadId [[ thread_position_in_grid ]]
) {
    const float4 colorAtThreadID = inTexture.read(threadId)
}
