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

kernel void findNinePointAverage(
    texture2d<float, access::read> image [[ texture(0) ]],
    device uint* result [[ buffer(0) ]],
    device uint* params [[ buffer(1) ]],
    uint threadId [[ thread_position_in_grid ]],
    uint numThreads [[ threads_per_grid ]]
) {
    float4 squareColor = float4(0.0, 0.0, 0.0, 0.0);
    
    const uint squaresInRow = params[0];
    const int imageWidth = params[1];
    const int imageHeight = params[2];
    
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

        squareColor.r = squareColor.r / float(squareHeight * squareWidth) * 100.0;
        squareColor.g = squareColor.g  / float(squareHeight * squareWidth) * 100.0;
        squareColor.b = squareColor.b  / float(squareHeight * squareWidth) * 100.0;
        result[squareIndex * 3 + 0] = uint(squareColor.r);
        result[squareIndex * 3 + 1] = uint(squareColor.g);
        result[squareIndex * 3 + 2] = uint(squareColor.b);
    }
}

kernel void findNinePointAverageAcrossThreadGroups(
                                 texture2d<float, access::read> image [[ texture(0) ]],
                                 device uint* result [[ buffer(0) ]],
                                 device uint* params [[ buffer(1) ]],
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
    
    const int squaresInRow = params[0];
    const int imageWidth = params[1];
    const int imageHeight = params[2];
    
    
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
            sum.r = sum.r  / (numRows * squareWidth) * 100.0;
            sum.g = sum.g  / (numRows * squareWidth) * 100.0;
            sum.b = sum.b  / (numRows * squareWidth) * 100.0;
            
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
    const uint gridsAcross = params[3];
    
    // The total number of nine-point squares in the entire photo
    uint ninePointSquares = numRows * numCols * gridsAcross * gridsAcross;
    
    for (uint squareIndex = threadId; squareIndex < ninePointSquares; squareIndex += numThreads) {
        float4 sum = float4(0.0, 0.0, 0.0, 0.0);
        
        uint gridSquareIndex = squareIndex / (gridsAcross * gridsAcross);
        uint gridSquareX = (gridSquareIndex % numCols) * gridSize;
        uint gridSquareY = (gridSquareIndex / numCols) * gridSize;
        
        uint ninePointIndex = squareIndex % (gridsAcross * gridsAcross);
        uint ninePointSize = gridSize / gridsAcross;
        uint ninePointX = gridSquareX + (( ninePointIndex % gridsAcross) * ninePointSize);
        uint ninePointY = gridSquareY + (( ninePointIndex / gridsAcross) * ninePointSize);
        
        for (uint deltaY = 0; deltaY < ninePointSize; deltaY++) {
            for (uint deltaX = 0; deltaX < ninePointSize; deltaX++) {
                uint2 coord = uint2(ninePointX + deltaX, ninePointY + deltaY);
                sum += image.read(coord);
            }
        }
        sum.r = sum.r / (ninePointSize * ninePointSize) * 100.0;
        sum.g = sum.g  / (ninePointSize * ninePointSize) * 100.0;
        sum.b = sum.b  / (ninePointSize * ninePointSize) * 100.0;
        
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
    device float* diffs   [[ buffer(4) ]],
    uint threadId [[ thread_position_in_grid ]],
    uint numThreads [[ threads_per_grid ]]
) {
    const int numCells = params[0];
    const int pointsPerTPA = numCells * 3;
    int refTPACount = params[1] / pointsPerTPA;
    int otherTPACount = params[2] / pointsPerTPA;
    
    
//    if (threadId < refTPACount) {
//        int minDiff = 0;
//        int minTPAId = 0;
//        for (int otherIndex = 0; otherIndex < otherTPACount; otherIndex++) {
//            int diff = 0;
//            for (int i = 0; i < pointsPerTPA; i++) {
//                diff += int(pow(float(int(refTPAs[pointsPerTPA*threadId + i]) - int(otherTPAs[pointsPerTPA*otherIndex + i])), 2.0));
//            }
//            if (diff < minDiff || minTPAId == 0) {
//                minDiff = diff;
//                minTPAId = otherIndex;
//            }
//            if (otherIndex < refTPACount) {
//                diffs[otherIndex] = minDiff;
//            }
//        }
//        result[threadId] = minTPAId;
////        diffs[threadId] = minDiff;
//    }

    
    for (int refTPAIndex = threadId; refTPAIndex < refTPACount; refTPAIndex += numThreads) {
        uint minTPAId = 0;
        float minDiff = 0.0;
        for (int otherIndex = 0; otherIndex < otherTPACount; otherIndex++) {
            float diff = 0.0;
            for (int delta = 0; delta < pointsPerTPA; delta++) {
//                diff += otherTPAs[otherIndex*pointsPerTPA + delta];
                diff += (float(refTPAs[refTPAIndex*pointsPerTPA + delta]) - float(otherTPAs[otherIndex*pointsPerTPA + delta])) *
                        (float(refTPAs[refTPAIndex*pointsPerTPA + delta]) - float(otherTPAs[otherIndex*pointsPerTPA + delta]));
            }
            if (minTPAId == 0 || diff < minDiff) {
                minTPAId = otherIndex;
                minDiff = diff;
            }
        }
        result[refTPAIndex] = minTPAId;
        diffs[refTPAIndex] = float(minDiff);
    }
}





















