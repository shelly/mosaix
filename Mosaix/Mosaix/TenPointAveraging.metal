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

kernel void findNinePointAverageSingleThreadGroup(
    texture2d<float, access::read> image [[ texture(0) ]],
    device uint* result [[ buffer(0) ]],
    uint threadId [[ thread_position_in_threadgroup ]],
    uint threadsInGroup [[ threads_per_threadgroup ]],
    uint threadGroupId [[ threadgroup_position_in_grid ]]
) {
    float4 squareColor = float4(0.0, 0.0, 0.0, 0.0);
    
    const int squaresInRow = 3;
    const int imageWidth = image.get_width();
    const int imageHeight = image.get_height();
    
    uint squareHeight = imageHeight / squaresInRow;
    uint squareWidth = imageWidth / squaresInRow;
    
    uint squareIndex = threadId;
    
    if (squareIndex < squaresInRow * squaresInRow) {
        uint squareRow = (squareIndex / squaresInRow);
        uint squareCol = squareIndex % squaresInRow;
        
        for (uint row = 0; row < squareHeight; row += 1) {
            uint pixelRow = squareHeight * squareRow + row;
            
            //Now, process that row of the square.
            for (uint delta = 0; delta < squareWidth; delta++) {
                uint pixelCol = squareWidth * squareCol + delta;
                uint2 coord = uint2(pixelCol, pixelRow);
                squareColor += image.read(coord);
            }
        }
        
        squareColor.r = squareColor.r * 255 / (squareHeight * squareWidth);
        squareColor.g = squareColor.g * 255 / (squareHeight * squareWidth);
        squareColor.b = squareColor.b * 255 / (squareHeight * squareWidth);
        result[squareIndex * 3 + 0] = squareColor.r;
        result[squareIndex * 3 + 1] = squareColor.g;
        result[squareIndex * 3 + 2] = squareColor.b;
    }
}

kernel void findNinePointAverage(
                                 texture2d<float, access::read> image [[ texture(0) ]],
                                 device uint* result [[ buffer(0) ]],
                                 uint threadId [[ thread_position_in_threadgroup ]],
                                 uint threadsInGroup [[ threads_per_threadgroup ]],
                                 uint threadGroupId [[ threadgroup_position_in_grid ]]
                                 ) {
    threadgroup atomic_uint red;
    threadgroup atomic_uint green;
    threadgroup atomic_uint blue;
    
    if (threadId == 0) {
        atomic_store_explicit(&red, 0, memory_order_relaxed);
        atomic_store_explicit(&green, 0, memory_order_relaxed);
        atomic_store_explicit(&blue, 0, memory_order_relaxed);
    }
    
    threadgroup_barrier(mem_flags::mem_device);
    
    const int squaresInRow = 3;
    const int imageWidth = image.get_width();
    const int imageHeight = image.get_height();
    
    
    uint squareHeight = imageHeight / squaresInRow;
    uint squareWidth = imageWidth / squaresInRow;
    
    uint squareIndex = threadGroupId;
    if (squareIndex < squaresInRow * squaresInRow) {
        float4 sum = float4(0.0, 0.0, 0.0, 0.0);
        int numRows = 0;
        for (uint row = threadId; row < squareHeight; row += threadsInGroup) {
            numRows++;
            uint squareRow = (squareIndex / squaresInRow);
            uint squareCol = squareIndex % squaresInRow;
            
            uint pixelRow = squareRow * squareHeight + row;
            
            //Now, process that row of the square.
            for (uint delta = 0; delta < squareWidth; delta++) {
                uint pixelCol = squareCol * squareHeight + delta;
                uint2 coord = uint2(pixelRow, pixelCol);
                float4 colorAtIndex = image.read(coord);
                sum += colorAtIndex;
            }
        }
        threadgroup_barrier(mem_flags::mem_device);
        if (numRows > 0) {
            sum.r = sum.r * 255 / (numRows * squareWidth);
            sum.g = sum.g * 255 / (numRows * squareWidth);
            sum.b = sum.b * 255 / (numRows * squareWidth);
            
            atomic_fetch_add_explicit(&red, int(sum.r), memory_order_relaxed);
            atomic_fetch_add_explicit(&green, int(sum.g), memory_order_relaxed);
            atomic_fetch_add_explicit(&blue, int(sum.b), memory_order_relaxed);
        }
        threadgroup_barrier(mem_flags::mem_device);
        
        int numWorkers = min(threadsInGroup, squareHeight);
        
        if (threadId == 0) {
            result[squareIndex * 3 + 0] = uint(atomic_load_explicit(&red, memory_order_relaxed) / numWorkers);
            result[squareIndex * 3 + 1] = uint(atomic_load_explicit(&green, memory_order_relaxed) / numWorkers);
            result[squareIndex * 3 + 2] = uint(atomic_load_explicit(&blue, memory_order_relaxed) / numWorkers);
        }
    }
}

kernel void findPhotoNinePointAverage(
     texture2d<float, access::read> image [[ texture(0) ]],
     device uint* params [[ buffer(0) ]],
     device uint* result [[ buffer(1) ]],
     uint threadId [[ thread_position_in_grid ]],
     uint numThreads [[ threads_per_grid ]]
) {
    
    const uint gridSize = params[0];
    const uint numRows = params[1];
    const uint numCols = params[2];
    
    // The total number of nine-point squares in the entire photo
    uint ninePointSquares = numRows * numCols * 9;
    
    for (uint squareIndex = threadId; squareIndex < ninePointSquares; squareIndex += numThreads) {
        float4 sum = float4(0.0, 0.0, 0.0, 0.0);
        
        uint gridSquareIndex = squareIndex / 9;
        uint gridSquareX = (gridSquareIndex % numCols) * gridSize;
        uint gridSquareY = (gridSquareIndex / numCols) * gridSize;
        
        uint ninePointIndex = squareIndex % 9;
        uint ninePointSize = gridSize / 3;
        uint ninePointX = gridSquareX + (( ninePointIndex % 3) * ninePointSize);
        uint ninePointY = gridSquareY + (( ninePointIndex / 3) * ninePointSize);
        
        for (uint deltaY = 0; deltaY < ninePointSize; deltaY++) {
            for (uint deltaX = 0; deltaX < ninePointSize; deltaX++) {
                                uint2 coord = uint2(ninePointX + deltaX, ninePointY + deltaY);
                                sum += image.read(coord);
            }
        }
        sum.r = sum.r * 255 / (ninePointSize * ninePointSize);
        sum.g = sum.g * 255 / (ninePointSize * ninePointSize);
        sum.b = sum.b * 255 / (ninePointSize * ninePointSize);
        
        result[squareIndex * 3 + 0] = uint(sum.r);
        result[squareIndex * 3 + 1] = uint(sum.g);
        result[squareIndex * 3 + 2] = uint(sum.b);
    }
}

kernel void findNearestMatches(
    device uint* refTPAs [[ buffer(0) ]],
    device uint* otherTPAs [[ buffer(1) ]],
    device uint* result  [[ buffer(2) ]],
    device uint* params  [[ buffer(3) ]],
    uint threadId [[ thread_position_in_grid ]],
    uint numThreads [[ threads_per_grid ]]
) {
    const uint pointsPerTPA = 9 * 3;
    uint refTPACount = params[0] / pointsPerTPA;
    uint otherTPACount = params[1] / pointsPerTPA;
    
    for (uint refTPAIndex = threadId; refTPAIndex < refTPACount; refTPAIndex += numThreads) {
        uint minTPAId = 0;
        float minDiff = 0.0;
        bool isChosen = (refTPAIndex == 29);
        uint minRGBVal = 255;
        for (uint otherIndex = 0; otherIndex < otherTPACount; otherIndex++) {
            float diff = 0.0;
            for (uint delta = 0; delta < pointsPerTPA; delta++) {
                uint refRGBVal = refTPAs[refTPAIndex*pointsPerTPA + delta];
                if (refRGBVal < minRGBVal) {
                    minRGBVal = refRGBVal;
                }
                diff += pow(abs(refRGBVal - otherTPAs[otherIndex*pointsPerTPA + delta]), 2.0);
            }
            if (minTPAId == 0 || diff < minDiff) {
                minTPAId = otherIndex;
                minDiff = diff;
            }
        }
        if (!isChosen || true) {
            result[refTPAIndex] = minTPAId;
        } else {
            result[refTPAIndex] = minRGBVal;
        }
    }
}





















