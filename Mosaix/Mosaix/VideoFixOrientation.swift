////
////  UIFixOrientation.swift
////  Mosaix
////
////  Adapted directly from: https://gist.github.com/matthiasnagel/fe7ed96dc66310c67b45fb759cf6de8c
////
//
//import Foundation
//import Photos
//import AVFoundation
//
//extension AVAssetImageGenerator {
//    
//    
//    var cgImage: CGImage!
//    
//    public func cgImageWithOrientation(time: CMTime) -> CGImage {
//        
//        self.cgImage = AVAssetImageGenerator.copyCGImage(at: time, actualTime: nil)
//        self.
//        if UIImageOrientation == UIImageOrientation.up {
//            return self.cgImage!
//        }
//        
//        var transform: CGAffineTransform = CGAffineTransform.identity
//        
//        switch imageOrientation {
//        case UIImageOrientation.down, UIImageOrientation.downMirrored:
//            transform = transform.translatedBy(x: size.width, y: size.height)
//            transform = transform.rotated(by: CGFloat(Double.pi))
//            break
//        case UIImageOrientation.left, UIImageOrientation.leftMirrored:
//            transform = transform.translatedBy(x: size.width, y: 0)
//            transform = transform.rotated(by: CGFloat(Double.pi / 2))
//            break
//        case UIImageOrientation.right, UIImageOrientation.rightMirrored:
//            transform = transform.translatedBy(x: 0, y: size.height)
//            transform = transform.rotated(by: CGFloat(-Double.pi / 2))
//            break
//        case UIImageOrientation.up, UIImageOrientation.upMirrored:
//            break
//        }
//        
//        switch imageOrientation {
//        case UIImageOrientation.upMirrored, UIImageOrientation.downMirrored:
//            transform.translatedBy(x: size.width, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//            break
//        case UIImageOrientation.leftMirrored, UIImageOrientation.rightMirrored:
//            transform.translatedBy(x: size.height, y: 0)
//            transform.scaledBy(x: -1, y: 1)
//        case UIImageOrientation.up, UIImageOrientation.down, UIImageOrientation.left, UIImageOrientation.right:
//            break
//        }
//        
//        let ctx: CGContext = CGContext(data: nil,
//                                       width: Int(size.width),
//                                       height: Int(size.height),
//                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
//                                       bytesPerRow: 0,
//                                       space: self.cgImage!.colorSpace!,
//                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
//        
//        ctx.concatenate(transform)
//        
//        switch imageOrientation {
//        case UIImageOrientation.left, UIImageOrientation.leftMirrored, UIImageOrientation.right, UIImageOrientation.rightMirrored:
//            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
//        default:
//            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
//            break
//        }
//        
//        let cgImage: CGImage = ctx.makeImage()!
//        return cgImage
//    }
//}
