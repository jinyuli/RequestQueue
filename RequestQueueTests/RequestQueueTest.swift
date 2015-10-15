//
//  RequestQueueTest.swift
//  Queue
//
//  Created by Jamse Li on 10/12/15.
//  Copyright © 2015 eLivingStore. All rights reserved.
//

import Foundation
import XCTest

@testable import RequestQueue

class RequestQueueTest: XCTestCase {
    
    typealias StringQueue = RequestQueue<String>
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAdd() {
        let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(3)
                callback(key:key, result:nil, error:nil, context:nil)
            })
        }
        let queue = StringQueue(op: op)
        
        let expect = expectationWithDescription("wait for queue")
        let key = "test1"
        let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            
            XCTAssertEqual(returnedKey, key, "should be the same key")
            expect.fulfill()
        }
        
        queue.add(key, value: value)
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(1, queue.map.count, "should be only 1 element in the queue")
        }
        
        waitForExpectationsWithTimeout(5) { (error:NSError?) -> Void in
            XCTAssertEqual(0, queue.map.count, "should be 0 now")
        }
    }
    
    func testRetry() {
        var retry:Int = 0;
        let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(2)
                //fail for the first time
                if retry == 0 {
                    callback(key:key, result:nil, error:NSError(domain: "test", code: 100, userInfo: nil), context:nil)
                    retry = 1
                } else {
                    callback(key:key, result:nil, error:nil, context:nil)
                }
            })
        }
        let queue = StringQueue(op: op, concurrentCount:1, maxRetryTimes:1)
        
        let expect = expectationWithDescription("wait for queue")
        let key = "test1"
        let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            
            XCTAssertEqual(returnedKey, key, "should be the same key")
            expect.fulfill()
        }
        
        queue.add(key, value: value)
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(1, queue.map.count, "should be only 1 element in the queue")
        }
        
        waitForExpectationsWithTimeout(5) { (error:NSError?) -> Void in
            XCTAssertEqual(retry, 1, "should be retried")
            XCTAssertEqual(0, queue.map.count, "should be 0 now")
        }
    }
    
    func testNoRetry() {
        var retry:Int = 0;
        let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(2)
                //fail for the first time
                if retry == 0 {
                    retry = 1
                    callback(key:key, result:nil, error:NSError(domain: "test", code: 100, userInfo: nil), context:nil)
                } else {
                    retry = 2
                    callback(key:key, result:nil, error:nil, context:nil)
                }
            })
        }
        let queue = StringQueue(op: op, concurrentCount:1, maxRetryTimes:0)
        
        let expect = expectationWithDescription("wait for queue")
        let key = "test1"
        let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            
            XCTAssertEqual(returnedKey, key, "should be the same key")
            expect.fulfill()
        }
        
        queue.add(key, value: value)
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(1, queue.map.count, "should be only 1 element in the queue")
        }
        
        waitForExpectationsWithTimeout(5) { (error:NSError?) -> Void in
            XCTAssertEqual(retry, 1, "should be no retry")
            XCTAssertEqual(0, queue.map.count, "should be 0 now")
        }
    }
    
    func testAdd_Remove() {
        let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(3)
                callback(key:key, result:nil, error:nil, context:nil)
            })
        }
        
        let queue = StringQueue(op: op, concurrentCount:1)
        
        let expect = expectationWithDescription("wait for queue")
        let key = "test1"
        let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            
            XCTAssertEqual(returnedKey, key, "should be the same key")
            expect.fulfill()
        }
        
        let key2 = "test2"
        let value2:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            
            XCTAssertEqual(returnedKey, key2, "should be the same key")
            expect.fulfill()
        }
        
        queue.add(key, value: value)
        queue.add(key2, value: value2)
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(2, queue.map.count, "should be two elements in the queue")
        }
        
        //remove one before it's executed
        queue.remove(key2)
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(1, queue.map.count, "should be only 1 element in the queue")
        }
        
        waitForExpectationsWithTimeout(5) { (error:NSError?) -> Void in
            XCTAssertEqual(0, queue.map.count, "should be 0 now")
        }
    }
    
    
    func testRemoveAll() {
        let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                NSThread.sleepForTimeInterval(3)
                callback(key:key, result:nil, error:nil, context:nil)
            })
        }
        let queue = StringQueue(op: op)
        
        let key = "test1"
        let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
            XCTFail("should have been removed, no callback")
        }
        
        queue.add(key, value: value)
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(1, queue.map.count, "should be only 1 element in the queue")
        }
        
        queue.removeAll()
        
        queue.queue.addOperationWithBlock { () -> Void in
            XCTAssertEqual(0, queue.map.count, "should be no element in the queue")
        }
        
        NSThread.sleepForTimeInterval(4)//wait for enough time
    }
    
    func testPerformance() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}

