//
//  RunLoopLock.swift
//  Rx
//
//  Created by Krunoslav Zaher on 11/5/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
    import RxSwift
#endif

#if os(Linux)
  func AtomicIncrement(increment: UnsafeMutablePointer<AtomicInt>) -> AtomicInt {
      increment.memory = increment.memory + 1
      return increment.memory
  }

  func AtomicDecrement(increment: UnsafeMutablePointer<AtomicInt>) -> AtomicInt {
      increment.memory = increment.memory - 1
      return increment.memory
  }
#endif

class RunLoopLock {
    let currentRunLoop: CFRunLoopRef

    var calledRun: AtomicInt = 0
    var calledStop: AtomicInt = 0

    init() {
        currentRunLoop = CFRunLoopGetCurrent()
    }

    func dispatch(action: () -> ()) {
        CFRunLoopPerformBlock(currentRunLoop, kCFRunLoopDefaultMode) {
            if CurrentThreadScheduler.isScheduleRequired {
                CurrentThreadScheduler.instance.schedule(()) { _ in
                    action()
                    return NopDisposable.instance
                }
            }
            else {
                action()
            }
        }
        CFRunLoopWakeUp(currentRunLoop)
    }

    func stop() {
        if AtomicIncrement(&calledStop) != 1 {
            return
        }
        CFRunLoopPerformBlock(currentRunLoop, kCFRunLoopDefaultMode) {
            CFRunLoopStop(self.currentRunLoop)
        }
        CFRunLoopWakeUp(currentRunLoop)
    }

    func run() {
        if AtomicIncrement(&calledRun) != 1 {
            fatalError("Run can be only called once")
        }
        CFRunLoopRun()
    }
}
