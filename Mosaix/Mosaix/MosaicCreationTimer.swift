//
//  MosaicCreationTimer.swift
//  Mosaix
//
//  Created by Nathan Eliason on 5/6/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import Foundation

enum MosaicCreationTimerError {
    case UnrecognizedTask
}


class MosaicCreationTimer {
    private var enabled: Bool
    private var tasks: [String : [(step: String, time: CFAbsoluteTime, elapsed: CFAbsoluteTime)]]

    
    init(enabled: Bool) {
        self.enabled = enabled
        self.tasks = [:]
    }
    
    func task(_ taskIdentifier: String) -> ((String) -> Void) {
        self.tasks[taskIdentifier] = [("start", CFAbsoluteTimeGetCurrent(), 0)]
        return {(step: String) -> Void in
            let lastTime = self.tasks[taskIdentifier]!.last!.time
            let currentTime = CFAbsoluteTimeGetCurrent()
            self.tasks[taskIdentifier]!.append((step, currentTime, currentTime - lastTime))
        }
    }
    
    func overallTaskTime(for taskIdentifier: String) -> CFAbsoluteTime? {
        if !(self.tasks.index(forKey: taskIdentifier) != nil) {
            return nil
        }
        return self.tasks[taskIdentifier]!.last!.time - self.tasks[taskIdentifier]!.first!.time
    }
    
    func complete(report: Bool) -> Void {
        if (report) {
            print("\nMosaic Creation Tasks:")
            print("---------------------------------------------------------")
            print("|             Step                    |   Elapsed Time  |")
            for (identifier, steps) in self.tasks {
                print("---------------------------------------------------------")
                print("| \(identifier)")
                for (step, _, elapsed) in steps {
                    print(String(format: "| %-35s | %10fs      |", (step as NSString).utf8String!, Float(elapsed)))
                }
            }
            print("---------------------------------------------------------")
        }
        self.tasks = [:]
    }
}

enum MosaicBenchmarkError : Error {
    case EmptyCondition
    case EmptyVariable
}

class MosaicBenchmarker {
    private var creator : MosaicCreator
    private var conditions : [String : (() -> Any?)]
    private var variables : [String : (() -> Any?)]
    
    init(creator: MosaicCreator) {
        self.creator = creator
        self.conditions = [:]
        self.variables = [:]
    }
    
    func addCondition(name: String, next: @escaping (() -> Any?)) {
        self.conditions[name] = next
    }
    
    func addVariable(name: String, next: @escaping (() -> Any?)) {
        print("Adding variable \(name)")
        self.variables[name] = next
    }
    
    func begin(tick: @escaping () -> Void, complete: @escaping () -> Void) throws -> Void {
        //Initialize all conditions and variablesdffd
        try self.creator.preprocess(complete: {() -> Void in
            for (_, next) in self.conditions {
                _ = next()
            }
            self.optimizeUnderCurrentConditions(tick: tick, complete: complete)
        })
    }
    
    func optimizeUnderCurrentConditions(tick: @escaping () -> Void, complete: () -> Void) -> Void {
        
        let numTrials : Int = 5
        var trialNum : Int = 1
        var avgTime : CFAbsoluteTime = 0
        
        func runNextTrial(varName: String, complete: @escaping () -> Void) -> Void {
            if (trialNum > numTrials) {
                //finish up
                complete()
            } else {
//                print("    Running trial \(trialNum)/\(numTrials)")
                do {
                    try self.creator.begin(tick: tick, complete: {() -> Void in
                        let trialTime = self.creator.timer.overallTaskTime(for: "Photo Mosaic Generation")
//                        print("      Trial \(trialNum) took \(trialTime!)s")
                        trialNum += 1
                        avgTime += trialTime! / Double(numTrials)
                        runNextTrial(varName: varName, complete: {() -> Void in
                            complete()
                        })
                    })
                } catch {
                    print("Error running benchmark: \(error)")
                }
            }
        }
        
        func trialNextVariable(varName: String, next: @escaping () -> Any?, complete: @escaping () -> Void) -> Void {
            let varVal = next()
            if (varVal == nil) {
                //finish up
                print("  Finished trialing \(varName)")
                complete()
            } else {
                print("  Set \(varName) = \(varVal!)")
                trialNum = 1
                avgTime = 0
                runNextTrial(varName: varName, complete: {() -> Void in
                    print("    Average time: \(avgTime)s")
                    trialNextVariable(varName: varName, next: next, complete: complete)
                })
            }
        }
        
        var varIt = self.variables.makeIterator()
        print("\(self.variables.count)")
        
        func optimizeNextVariable() {
            let nextVar = varIt.next()
            if (nextVar != nil) {
                print("Now optimizing for \(nextVar!.key).")
                trialNextVariable(varName: nextVar!.key, next: nextVar!.value, complete: {() -> Void in
                    optimizeNextVariable()
                })
            }
        }
        
        optimizeNextVariable()
    }
}
































