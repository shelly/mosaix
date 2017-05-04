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


// Thread ID == (thread position in thread group) + (thread group position in grid * threads per thread group)

// Each threadgroup handles a different section of the image.

kernel void findNinePointAverage(
    texture2d<float, access::read> image [[ texture(0) ]],
    device int3* result [[ buffer(0) ]],
    uint threadId [[ thread_position_in_threadgroup ]],
    uint threadsInGroup [[ threads_per_threadgroup ]],
    uint threadGroupId [[ threadgroup_position_in_grid ]]
) {
//    if (threadId < 10) {
//        result[threadId].r = 15;
//        result[threadId].g = 20;
//        result[threadId].b = 24;
//    }
    threadgroup atomic_uint red;
    threadgroup atomic_uint green;
    threadgroup atomic_uint blue;
    
    const int squaresInRow = 3;
    const int imageWidth = image.get_width();
    const int imageHeight = image.get_height();
    
    
    uint squareHeight = imageHeight / squaresInRow;
    uint squareWidth = imageWidth / squaresInRow;
    
    uint squareIndex = threadGroupId;
    if (squareIndex < 9) {
        float3 sum = float3(0.0, 0.0, 0.0);
        for (uint row = threadId; row < squareHeight; row += threadsInGroup) {
            uint squareRow = (squareIndex / squaresInRow);
            uint squareCol = squareIndex % squaresInRow;
            
            //uint startingPixel = imageRow * (squareHeight * imageWidth) + (imageCol * squareWidth);
            
            uint pixelRow = squareRow * squareHeight;
            
            //Now, process that row of the square.
            for (uint delta = 0; delta < squareWidth; delta++) {
                uint2 coord = uint2(pixelRow, squareCol*squareWidth + delta);
                float4 colorAtIndex = image.read(coord);
                sum += float3(colorAtIndex);
            }
        }
        
        atomic_fetch_add_explicit(&red, int(sum.r), memory_order_relaxed);
        atomic_fetch_add_explicit(&green, int(sum.g), memory_order_relaxed);
        atomic_fetch_add_explicit(&blue, int(sum.b), memory_order_relaxed);
        
        threadgroup_barrier(mem_flags::mem_device);
        
        if (threadId == 0) {
            result[squareIndex].r = 10;
            result[squareIndex].g = 15;
            result[squareIndex].b = 20;
//            result[squareIndex].r = atomic_load_explicit(&red, memory_order_relaxed);
//            result[squareIndex].g = atomic_load_explicit(&green, memory_order_relaxed);
//            result[squareIndex].b = atomic_load_explicit(&blue, memory_order_relaxed);
        }
    }
}


//for (int i = threadId; i < numSquares * gridSize; i += numThreads) {
//    squareIndex = i % numSquares;
//    squareRow = i / numSquares;
//    
//    int imageRow = (squareIndex / squaresInRow) * gridSize + squareRow;
//    int imageCol = (squareIndex % squaresInRow) * gridSize;
//    
//    int startingPixel = imageRow * squaresInRow * gridSize + imageCol;
//    
//    //Now, process that row.
//    float3 sum = float3(0.0, 0.0, 0.0);
//    for (int delta = 0; delta < gridSize; delta++) {
//        pixelIndex = startingPixel + delta;
//        float4 colorAtIndex = image.read(pixelIndex);
//        sum.r += colorAtIndex.r;
//        sum.g += colorAtIndex.g;
//        sum.b += colorAtIndex.b;
//    }
//    
//    atomic_fetch_add_explicit(&reds[squareIndex], int(sum.r), memory_order_relaxed);
//    atomic_fetch_add_explicit(&greens[squareIndex], int(sum.g), memory_order_relaxed);
//    atomic_fetch_add_explicit(&blues[squareIndex], int(sum.b), memory_order_relaxed);
//}
//
//threadgroup_barrier(mem_flags::mem_device);
//
//if (threadId < 10) {
//    result[threadId] = int3(red, green, blue);
//}
//}
