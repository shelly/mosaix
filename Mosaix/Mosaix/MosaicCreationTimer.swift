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
    
    func report() -> Void {
        print("\nMosaic Creation Tasks:")
        print("---------------------------------------------------------")
        print("|             Step                    |   Elapsed Time          |")
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
