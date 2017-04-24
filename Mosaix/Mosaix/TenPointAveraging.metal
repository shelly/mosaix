//
//  TenPointAveraging.metal
//  Mosaix
//
//  Created by Nathan Eliason on 4/19/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//
//

#include <metal_stdlib>
using namespace metal;


// Thread ID == (thread position in thread group)  +    (thread group position in grid * threads per thread group)

kernel void findNinePointAverage(
    texture2d<float4, access:read> image [[ texture(0) ]],
    device int3* result [[ buffer(0) ]],
    uint gridSize [[ buffer[1] ]],
    uint threadId [[ thread_position_in_grid ]]
) {
    device atomic_int *reds   = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    device atomic_int *greens = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    device atomic_int *blues  = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    
    const int squaresInRow = 3;
    const int numSquares = squaresInRow * squaresInRow;
    int squareIndex;
    int squareRow;
    int pixelIndex;

    for (int i = threadId; i < numSquares * gridSize; i += numThreads) {
        squareIndex = i % numSquares;
        squareRow = i / numSquares;
        
        int imageRow = (squareIndex / squaresInRow) * gridSize + squareRow;
        int imageCol = (squareIndex % squaresInRow) * gridSize;
        
        int startingPixel = imageRow * squaresInRow * gridSize + imageCol;
        
        //Now, process that row.
        float3 sum = float3(0.0, 0.0, 0.0);
        for (int delta = 0; delta < gridSize; delta++) {
            pixelIndex = startingPixel + delta;
            float4 colorAtIndex = image.read(pixelIndex);
            sum.r += colorAtIndex.r;
            sum.g += colorAtIndex.g;
            sum.b += colorAtIndex.b;
        }
        
        atomic_fetch_add_explicit(&reds[squareIndex], Int(sum.r), memory_order_relaxed);
        atomic_fetch_add_explicit(&greens[squareIndex], Int(sum.g), memory_order_relaxed);
        atomic_fetch_add_explicit(&blues[squareIndex], Int(sum.b), memory_order_relaxed);
    }
    
    threadgroup_barrier(memflags::mem_device);
    
    if (threadId < 10) {
        result[threadId] = int3(reds[threadId], greens[threadId], blues[threadId]);
    }
}
