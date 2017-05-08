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
        if !self.tasks.contains(taskIdentifier) {
            return nil
        }
        return self.tasks[taskIdentifier]!.last!.time - self.tasks[taskIdentifier]!.first!.time
    }
    
    func report() -> Void {
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
        self.variables[name] = next
    }
    
    func begin() throws -> Void {
        //Initialize all conditions and variablesdffd
        try self.creator.preprocess(complete: {() -> Void in
            for (_, next) in self.conditions {
                _ = next()
            }
            self.optimizeUnderCurrentConditions()
        })
    }
    
    func optimizeUnderCurrentConditions() -> Void {
        
        let numTrials : Int = 5
        
        func runNextTrial(_ trialNum: Int, varName: String, complete: @escaping (CFAbsoluteTime) -> Void) -> Void {
            print("    Running trial \(trialNum)/\(numTrials)")
            if (trialNum > numTrials) {
                //finish up
                complete(0)
            } else {
                do {
                    try self.creator.begin(tick: {() -> Void in return}, complete: {() -> Void in
                        let trialTime = self.creator.timer.overallTaskTime(for: "Mosaic Photo Generation")
                        runNextTrial(trialNum + 1, varName: varName, complete: {(sumTime : CFAbsoluteTime) -> Void in
                            complete(sumTime + trialTime/numTrials)
                        })
                    })
                } catch {
                    print("Error running benchmark: \(error)")
                }
            }
        }
        
        func trialNextVariable(varName: String, next: () -> Any?, complete: () -> Void) -> Void {
            let varVal = next()
            if (varVal == nil) {
                //finish up
                print("  Finished trialing \(varName)")
                complete()
            } else {
                print("  Set \(varName)=\(varVal!)")
                runNextTrial(1, varName: varName, complete: {(avgTime: CFAbsoluteTime) -> Void in
                    print("    Took \(avgTime)s")
                    trialNextVariable(varName: varName, next: next, complete: complete)
                })
            }
        }
        
        var varIt = self.variables.makeIterator()
        
        func optimizeNextVariable() {
            let nextVar : (name: String, next: (() -> Any?))? = varIt.next() as? (name: String, next: (() -> Any?))
            print("Now optimizing for \(nextVar!.name).")
            if (nextVar != nil) {
                trialNextVariable(varName: nextVar!.name, next: nextVar!.next, complete: {() -> Void in
                    optimizeNextVariable()
                })
            }
        }
        
        optimizeNextVariable()
    }
}
































