//
//  MetalPipeline.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class MetalPipeline {
    let device : MTLDevice
    let commandQueue : MTLCommandQueue
    let library: MTLLibrary
    let NinePointAverage : MTLFunction
    let PhotoNinePointAverage : MTLFunction
    let FindNearestMatches : MTLFunction
    var pipelineState : MTLComputePipelineState? = nil
    var photoPipelineState : MTLComputePipelineState? = nil
    var matchesPipelineState : MTLComputePipelineState? = nil
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()
        self.library = self.device.newDefaultLibrary()!
        self.NinePointAverage = self.library.makeFunction(name: "findNinePointAverage")!
        self.PhotoNinePointAverage = self.library.makeFunction(name: "findPhotoNinePointAverage")!
        self.FindNearestMatches = self.library.makeFunction(name: "findNearestMatches")!
        do {
            self.pipelineState = try self.device.makeComputePipelineState(function: self.NinePointAverage)
            self.photoPipelineState = try self.device.makeComputePipelineState(function: self.PhotoNinePointAverage)
            self.matchesPipelineState = try self.device.makeComputePipelineState(function: self.FindNearestMatches)
        } catch {
            print("Error initializing pipeline state!")
        }
    }
    
    func getImageTexture(image: CGImage) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self.device)
        return try textureLoader.newTexture(with: image)
    }
    
    private func getImageTextureRaw(image: CGImage) -> MTLTexture {
        let rawData = calloc(image.height * image.width * 4, MemoryLayout<UInt8>.size)
        let bytesPerRow = 4 * image.width
        let options = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let context = CGContext(
            data: rawData,
            width: image.width,
            height: image.height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: options
        )
        
        context?.draw(image, in : CGRect(x:0, y: 0, width: image.width, height: image.height))
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: image.width,
            height: image.height,
            mipmapped: true
        )
        
        let texture : MTLTexture = self.device.makeTexture(descriptor: textureDescriptor)
        texture.replace(region: MTLRegionMake2D(0, 0, image.width, image.height),
                        mipmapLevel: 0,
                        slice: 0,
                        withBytes: rawData!,
                        bytesPerRow: bytesPerRow,
                        bytesPerImage: bytesPerRow * image.height)
        free(rawData)
        return texture
    }
    
    func processImageTexture(texture: MTLTexture, width: Int, height: Int, threadWidth: Int, complete : @escaping ([UInt32]) -> Void) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.pipelineState!)
        commandEncoder.setTexture(texture, at: 0)
        
        let bufferCount = 3 * TenPointAverageConstants.numCells
        let bufferLength = MemoryLayout<UInt32>.size * bufferCount
        let resultBuffer = self.device.makeBuffer(length: bufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 0)
        
        let paramBufferLength = MemoryLayout<UInt32>.size * 3;
        let options = MTLResourceOptions()
        let params = UnsafeMutableRawPointer.allocate(bytes: paramBufferLength, alignedTo: 1)
        params.storeBytes(of: UInt32(TenPointAverageConstants.gridsAcross), toByteOffset: 0, as: UInt32.self)
        params.storeBytes(of: UInt32(width), toByteOffset: 4, as: UInt32.self)
        params.storeBytes(of: UInt32(height), toByteOffset: 8, as: UInt32.self)
        let paramBuffer = self.device.makeBuffer(bytes: params, length: paramBufferLength, options: options)
        commandEncoder.setBuffer(paramBuffer, offset: 0, at: 1)
        
        
        let gridSize : MTLSize = MTLSize(width: 8, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: 32, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            if (buffer.error != nil) {
                print("There was an error completing an image texture: \(buffer.error!.localizedDescription)")
            } else {
                let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: bufferCount))
                //            print("\(results)")
                complete(results)
            }
        })
        commandBuffer.commit()
    }
    
    func processEntirePhotoTexture(texture: MTLTexture, gridSize: Int, numGridSpaces: Int, rows: Int, cols: Int, threadWidth: Int, complete: @escaping ([UInt32]) -> Void) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.photoPipelineState!)
        commandEncoder.setTexture(texture, at: 0)

        
        let paramBufferLength = MemoryLayout<UInt32>.size * 4;
        let options = MTLResourceOptions()
        let params = UnsafeMutableRawPointer.allocate(bytes: paramBufferLength, alignedTo: 1)
        print("gridSize: \(gridSize)")
        params.storeBytes(of: UInt32(gridSize), as: UInt32.self)
        params.storeBytes(of: UInt32(rows), toByteOffset: 4, as: UInt32.self)
        params.storeBytes(of: UInt32(cols), toByteOffset: 8, as: UInt32.self)
        params.storeBytes(of: UInt32(TenPointAverageConstants.gridsAcross), toByteOffset: 12, as: UInt32.self)
        print("PROCESSING ENTIRE PHOTO ROWS: \(rows) COLS: \(cols)")
        let paramBuffer = self.device.makeBuffer(bytes: params, length: paramBufferLength, options: options)
        commandEncoder.setBuffer(paramBuffer, offset: 0, at: 0)
        
        
        print("num grid squares: \(numGridSpaces)")
        let bufferCount = 3 * TenPointAverageConstants.numCells * numGridSpaces
        let bufferLength = MemoryLayout<UInt32>.size * bufferCount
        let resultBuffer = self.device.makeBuffer(length: bufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 1)
        
        let gridSize : MTLSize = MTLSize(width: 16, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: 32, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            if (buffer.error != nil) {
                print("There was an error finding the TPA of the reference photo: \(buffer.error!.localizedDescription)")
            } else {
                let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: bufferCount))
//                print("\(results)")
                complete(results)
            }
        })
        commandBuffer.commit()
    }
    
    func processNearestAverages(refTPAs: [UInt32], otherTPAs: [UInt32], rows: Int, cols: Int, threadWidth: Int, complete: @escaping([UInt32], [Float32]) -> Void) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        commandEncoder.setComputePipelineState(self.matchesPipelineState!)
        
        let refBuffer = self.device.makeBuffer(bytes: UnsafeRawPointer(refTPAs), length: MemoryLayout<UInt32>.size * refTPAs.count)
        commandEncoder.setBuffer(refBuffer, offset: 0, at: 0)
        
        let tpaBuffer = self.device.makeBuffer(bytes: UnsafeRawPointer(otherTPAs), length: MemoryLayout<UInt32>.size * otherTPAs.count)
        commandEncoder.setBuffer(tpaBuffer, offset: 0, at: 1)
        
        let resultBufferLength = MemoryLayout<UInt32>.size * rows * cols
        let resultBuffer = self.device.makeBuffer(length: resultBufferLength)
        commandEncoder.setBuffer(resultBuffer, offset: 0, at: 2)
        
        let paramBufferLength = MemoryLayout<UInt32>.size * 4;
        let params = UnsafeMutableRawPointer.allocate(bytes: MemoryLayout<UInt32>.size, alignedTo: 1)
        //        print("params: [\(refTPAs.count), \(otherTPAs.count)]")
        params.storeBytes(of: UInt32(TenPointAverageConstants.numCells), as: UInt32.self)
        params.storeBytes(of: UInt32(refTPAs.count), toByteOffset: 4, as: UInt32.self)
        params.storeBytes(of: UInt32(otherTPAs.count), toByteOffset: 8, as: UInt32.self)
        params.storeBytes(of: UInt32(cols), toByteOffset: 12, as: UInt32.self)
        let paramBuffer = self.device.makeBuffer(bytes: params, length: paramBufferLength)
        commandEncoder.setBuffer(paramBuffer, offset: 0, at: 3)
        
        let diffBuffer = self.device.makeBuffer(length: MemoryLayout<Float32>.size * rows * cols)
        commandEncoder.setBuffer(diffBuffer, offset: 0, at: 4)
        
        
        let gridSize : MTLSize = MTLSize(width: 8, height: 1, depth: 1)
        let threadGroupSize : MTLSize = MTLSize(width: 64, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            if (buffer.error != nil) {
                print("There was an error completing the TPA matching: \(buffer.error!.localizedDescription)")
            } else {
                let results : [UInt32] = Array(UnsafeBufferPointer(start: resultBuffer.contents().assumingMemoryBound(to: UInt32.self), count: rows * cols))
                let diff : [Float32] = Array(UnsafeBufferPointer(start: diffBuffer.contents().assumingMemoryBound(to: Float32.self), count: rows * cols))
//                            print("\(results)")
                complete(results, diff)
            }
        })
        //        print("2")
        commandBuffer.commit()
        //        print("committed")
    }
}
