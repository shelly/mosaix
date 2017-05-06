//
//  KDTree.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/5/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation
import Photos

/**
 *     27-Dimensional implementation of KD Trees.
 *     TPA = {
 *          [r, g, b], [r, g, b], [r, g, b],
 *          [r, g, b], [r, g, b], [r, g, b],
 *          [r, g, b], [r, g, b], [r, g, b]
 *     }
 *
 *     axis_order = [
 *          [ 0,  9, 18], [19,  1, 10], [11, 20,  2],
 *          [21,  3, 12], [13, 22,  4], [ 5, 14, 23],
 *          [15, 24,  6], [ 7, 16, 25], [26,  8, 17]
 *     ]
 *
 *     axis_order[i] = [i % 9][ (i + i/3 + i/9) % 3 ]
 *
 */

private class KDNode: NSObject, NSCoding {
    let tpa: TenPointAverage
    let asset: String
    var left: KDNode? = nil
    var right: KDNode? = nil
    
    init(tpa: TenPointAverage, asset: String) {
        self.tpa = tpa
        self.asset = asset
    }
    
    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        self.tpa = aDecoder.decodeObject(forKey: "tpa") as! TenPointAverage
        self.asset = aDecoder.decodeObject(forKey: "asset") as! String
        
        if let left = aDecoder.decodeObject(forKey: "left") as? KDNode {
            self.left = left
        } else {
            self.left = nil
        }
        
        if let right = aDecoder.decodeObject(forKey: "right") as? KDNode {
            self.right = right
        } else {
            self.right = nil
        }
        
        super.init()
    }
    
    func encode(with aCoder: NSCoder) -> Void{
        aCoder.encode(self.tpa, forKey: "tpa")
        aCoder.encode(self.asset, forKey: "asset")
        if (self.left != nil) {
            aCoder.encode(self.left, forKey: "left")
        }
        if (self.right != nil) {
        aCoder.encode(self.right, forKey: "right")
        }
    }
}

enum TPAComparison {
    case less
    case equal
    case greater
}

class KDTree : NSObject, NSCoding, TPAStorage {

    public var pListPath = "kdtree.plist"
    private var root : KDNode? = nil
    private var assets : Set<String>
    
    required override init() {
        self.assets = []
    }
    
    func insert(asset: String, tpa: TenPointAverage) {
        self.root = self.insert(asset, tpa, at: self.root, level: 0)
    }
    
    
    /**
     * Given the local identifier for a photo and the ten-point average struct (and a root node), this 
     * recursively inserts a new node containing this information below the given node. Note that 
     * the data structure is not self-balancing and relies on probability for expected logarithmic 
     * insertions and accesses.
     */
    private func insert(_ asset: String, _ tpa: TenPointAverage, at node: KDNode?, level: Int) -> KDNode {
        if (node == nil) {
            self.assets.insert(asset)
            return KDNode(tpa: tpa, asset: asset)
        }
        
        let comparison = self.compareAtLevel(tpa, node!.tpa, atLevel: level)
        
        if (comparison == TPAComparison.less) {
            node!.left = insert(asset, tpa, at: node!.left, level: level + 1)
        } else {
            node!.right = insert(asset, tpa, at: node!.right, level: level + 1)
        }
        
        return node!
    }
    
    private func compareAtLevel(_ left: TenPointAverage, _ right: TenPointAverage, atLevel: Int) -> TPAComparison {
        let difference: Float = self.differenceAtLevel(left, right, atLevel: atLevel)
        if (difference < 0) {
            return TPAComparison.less
        } else if (difference == 0) {
            return TPAComparison.equal
        } else {
            return TPAComparison.greater
        }
    }
    
    /**
     * Returns the distance between the left and right TenPointAverages along the axis determined by atLevel.
     *
     * The result is always non-negative.
     */
    private func distanceAtLevel(_ left: TenPointAverage, _ right: TenPointAverage, atLevel: Int) -> Float {
        return Float(abs(self.differenceAtLevel(left, right, atLevel: atLevel)))
    }
    
    /**
     * Returns the difference between left and right along the axis defined by atLevel. As each level splits along
     * another of this implementation's 27 axes, we find the grid index and RGB values by the current level and 
     * compare the values of those only.
     */
    private func differenceAtLevel(_ left: TenPointAverage, _ right: TenPointAverage, atLevel: Int) -> Float {
        let gridIndex : Int = atLevel % 9
        let rgb : Int = (atLevel + (atLevel/3) + (atLevel/9)) % 3
        
        let leftPixel = left.gridAvg[gridIndex / 3][gridIndex % 3]
        let rightPixel = right.gridAvg[gridIndex / 3][gridIndex % 3]
        
        return Float(leftPixel.get(rgb) - rightPixel.get(rgb))
    }
    
    func isMember(_ asset: String) -> Bool {
        return self.assets.contains(asset)
    }
    
    func findNearestMatch(to refTPA: TenPointAverage) -> (closest: String, diff: Float)? {
        return self.findNearestMatch(to: refTPA, from: self.root, level: 0)
    }
    
    /**
     * The recursive algorithm for KD-Tree nearest-neighbor search. According to the given comparison method, explores 
     * the tree and uses hypersphere distance checks to eliminate the branch, with expected log(n) queries to find the 
     * ten-point average closest to that of the given refTPA. 
     *
     * Returns nil if and only if the tree is empty. Otherwise, returns the local identifier of the photo and the 
     * calculated difference (lower is better).
     */
    private func findNearestMatch(to refTPA: TenPointAverage, from node: KDNode?, level: Int) -> (closest: String, diff: Float)? {
        var currentBest : (closest: String, diff: Float)?
        
        //Base Case
        if (node == nil) {
            return nil
        }
        
        //Recursively get best from leaves
        let comparison = self.compareAtLevel(refTPA, node!.tpa, atLevel: level)
        if (comparison == TPAComparison.less) {
            currentBest = self.findNearestMatch(to: refTPA, from: node!.left, level: level + 1)
        } else {
            currentBest = self.findNearestMatch(to: refTPA, from: node!.right, level: level + 1)
        }
        
        //Then, on the way back up, see if current node is better.
        let currentDiff : Float = Float(refTPA - node!.tpa)
        if (currentBest == nil || currentDiff < currentBest!.diff) {
            // Node is better than currentBest
            currentBest = (closest: node!.asset, diff: currentDiff)
        }
        
        //Now, check to see if the _other_ branch potentially has a closer node.
        var otherBest : (closest: String, diff: Float)? = nil
        if (comparison == TPAComparison.less && (currentBest == nil || self.isCloser(refTPA, to: node!.right, than: currentBest!.diff, atLevel: level + 1))) {
            otherBest = self.findNearestMatch(to: refTPA, from: node!.right, level: level + 1)
        } else if (comparison == TPAComparison.greater && (currentBest == nil || self.isCloser(refTPA, to: node!.left, than: currentBest!.diff, atLevel: level + 1))) {
            otherBest = self.findNearestMatch(to: refTPA, from: node!.left, level: level + 1)
        }
        if (otherBest != nil && (currentBest == nil || otherBest!.diff < currentBest!.diff)) {
            currentBest = otherBest
        }
        
        return currentBest
    }
    
    /**
     * Works just like findNearestMatch, but always explores the entire tree in search of the best match. According to KD-Tree theory 
     * this should return the same result. This implementation is left here to verify correctness.
     */
    private func findNearestMatchBruteForce(to refTPA: TenPointAverage, from node: KDNode?, level: Int) -> (closest: String, diff: Float)? {
        //Base Case
        if (node == nil) {
            return nil
        }
        
        let leftBest = self.findNearestMatch(to: refTPA, from: node!.left, level: level + 1)
        let rightBest = self.findNearestMatch(to: refTPA, from: node!.right, level: level + 1)
        let currentDiff : Float = Float(refTPA - node!.tpa)

        let leftBetter = leftBest != nil && leftBest!.diff < currentDiff
        let rightBetter = rightBest != nil && rightBest!.diff < currentDiff

        if (leftBetter && rightBetter) {
            if (leftBest!.diff < rightBest!.diff) {
                return leftBest
            } else {
                return rightBest
            }
        } else if (leftBetter) {
            return leftBest
        } else if (rightBetter) {
            return rightBest
        } else {
            return (node!.asset, currentDiff)
        }
    }
    
    /**
     * Returns true if and only if the given node is non-nil and distance at the given level
     * is less than `diff`.
     */
    private func isCloser(_ tpa: TenPointAverage, to node: KDNode? , than diff: Float, atLevel: Int) -> Bool {
        if (node == nil) {
            return false
        }
        return self.distanceAtLevel(tpa, node!.tpa, atLevel: atLevel) < diff
    }
    
    //NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        self.assets = []
        self.assets = aDecoder.decodeObject(forKey: "assets") as! Set<String>
        if let root = aDecoder.decodeObject(forKey: "root") as? KDNode {
            self.root = root
        } else {
            self.root = nil
        }
        super.init()
    }
    
    func encode(with aCoder: NSCoder) -> Void{
        aCoder.encode(root, forKey: "root")
        aCoder.encode(assets, forKey: "assets")
    }
}
