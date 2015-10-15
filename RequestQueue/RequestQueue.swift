//
//  ELSRequestQueue.swift
//  ELSQueue
//
//  Created by Jamse Li on 10/9/15.
//  Copyright © 2015 eLivingStore. All rights reserved.
//

import Foundation

/**
 *
 *
 *
 */
public class RequestQueue<Key: Hashable> {
    
    public typealias OperationCallback = (key:Key, result:Any?, error:NSError?, context:Any?) -> Void
    public typealias Operation = (key: Key, callback:OperationCallback) -> Void
    
    /**
     * Running items, operation has been called
     */
    var running = Set<Key>()
    
    /**
     * Store all the items(running, or to run).
     */
    var map:[Key:[OperationCallback]] = [Key: [OperationCallback]]()
    
    /**
     * All keys in the order of adding to queue
     */
    var keys: [Key] = [Key]()
    
    /**
     * Store times that items have been retried after op fails.
     * If maxRetryTimes <= 0, the item will not be retried
     */
    var retriedKeys: [Key: Int] = [Key: Int]()
    
    /**
     * inner property. handle callback from operation
     */
    var opCallback:OperationCallback?
    
    /**
     *if maxRetryTimes > 0:
     *    once operation failed(error is not nil), the key will be added to the tail of waiting queue
     */
    var maxRetryTimes: Int = 0
    
    /**
     * Used to store result from operation, it's optional
     */
    let cache: BaseCache<Key, Any>?
    
    /**
     * inner property, the queue is single thread queue, used to control/schedule operations
     */
    let queue:NSOperationQueue
    
    /**
     * callback queue, it's main queue by default.
     */
    public let callbackQueue:NSOperationQueue
    
    /**
     * the operation that is used to execute code according a given key. and once it finishes, 
     * callback must be called.
     * Note that op should not block the calling thread.
     */
    public let op: Operation
    
    /**
     * the max number of operations that could run at the same time. by default it's 5.
     */
    public let concurrentCount:UInt32
    
    public convenience init(op:Operation) {
        self.init(op:op, cache:nil, callbackQueue:NSOperationQueue.mainQueue(), concurrentCount: 5, maxRetryTimes:0)
    }
    
    public convenience init(op:Operation, concurrentCount:UInt32) {
        self.init(op:op, cache:nil, callbackQueue:NSOperationQueue.mainQueue(), concurrentCount:concurrentCount, maxRetryTimes:0)
    }
    
    public convenience init(op:Operation, concurrentCount:UInt32, maxRetryTimes:Int) {
        self.init(op:op, cache:nil, callbackQueue:NSOperationQueue.mainQueue(), concurrentCount:concurrentCount, maxRetryTimes:maxRetryTimes)
    }
    
    public convenience init(op:Operation, cache:BaseCache<Key, Any>?, concurrentCount:UInt32, maxRetryTimes:Int) {
        self.init(op:op, cache:cache, callbackQueue:NSOperationQueue.mainQueue(), concurrentCount:concurrentCount, maxRetryTimes:maxRetryTimes)
    }
    
    public init(op:Operation, cache:BaseCache<Key, Any>?, callbackQueue:NSOperationQueue, concurrentCount:UInt32, maxRetryTimes: Int) {
        self.op = op
        self.queue = NSOperationQueue()
        self.queue.maxConcurrentOperationCount = 1
        self.callbackQueue = callbackQueue
        self.concurrentCount = concurrentCount
        self.maxRetryTimes = maxRetryTimes
        self.cache = cache
    }
    
    public func add(key:Key, value :OperationCallback) {
        self.queue.addOperationWithBlock { [unowned self]() -> Void in
            self.setOpCallback()
            var array:[OperationCallback]? = self.map[key]
            if array == nil {
                array = [OperationCallback]()
                
                self.keys.append(key)
            }
            array!.append(value)
            self.map[key] = array
            self.run()
        }
    }
    
    public func remove(key:Key) {
        self.queue.addOperationWithBlock { () -> Void in
            self.map.removeValueForKey(key)
            if let index = self.keys.indexOf(key) {
                self.keys.removeAtIndex(index)
            }
        }
    }
    
    public func removeAll(){
        self.queue.addOperationWithBlock { () -> Void in
            self.map.removeAll()
            self.running.removeAll()
        }
    }
    
    func run() {
        if self.running.count >= Int(self.concurrentCount) {
            return
        }
        if let key = self.keys.first {
            self.keys.removeFirst()
            self.running.insert(key)
            self.op(key: key, callback: self.opCallback!)
        }
    }
    
    func setOpCallback() {
        if self.opCallback == nil {
            self.opCallback = { [unowned self] (key:Key, result:Any?, error:NSError?, context:Any?) in
                self.queue.addOperationWithBlock({ () -> Void in
                    self.running.remove(key)
                    if let obj = result {
                        if self.cache != nil {
                            self.cache![key] = obj
                        }
                    }
                    var needRetry = false
                    if error != nil && self.maxRetryTimes > 0 {
                        if let times = self.retriedKeys[key] {
                            needRetry = times < self.maxRetryTimes
                        } else {
                            needRetry = true
                        }
                    }
                    if needRetry {
                        var times = self.retriedKeys[key]
                        if times == nil {
                            times = 0
                        }
                        self.retriedKeys[key] = times! + 1
                        self.keys.append(key)
                    } else {
                        if let array = self.map.removeValueForKey(key) {
                            self.callbackQueue.addOperationWithBlock({ () -> Void in
                                for value in array {
                                    value(key: key, result: result, error: error, context: context)
                                }
                            })
                        }
                        self.retriedKeys.removeValueForKey(key)
                    }
                    
                    self.run()
                })
            }
        }
    }
}