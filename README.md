# RequestQueue
A queue that control async requests(for example, image request), to avoid multiple requests sent out for the same resource

## Usage

```swift
let op: StringQueue.Operation = {(key: String, callback: StringQueue.OperationCallback) in
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            NSThread.sleepForTimeInterval(3)
            callback(key:key, result:nil, error:nil, context:nil)
        })
    }
let queue = StringQueue(op: op)
let key = "test1"
let value:StringQueue.OperationCallback = {(returnedKey:String, result:Any?, error:NSError?, context:Any?) in
                                                    //do anything with result or errr
                                                }
queue.add(key, value: value)
                                                                                                                                    
```

### TODOS
  * Add some default queues, such as image queue
  * Add some cache implementations


### Version 0.0.1
  * Add the basic implementation of queue
