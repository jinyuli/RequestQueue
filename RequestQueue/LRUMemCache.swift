//
//  LRUMemCache.swift
//  RequestQueue
//
//  Created by Jamse Li on 10/15/15.
//  Copyright © 2015 eLivingStore. All rights reserved.
//

import Foundation

public class LRUMemCache<Key: Hashable, Value> : BaseCache<Key, Value> {
    var map = [Key: Value]()
    var sortedKeys = [Key]()
    
    public required init(maxItemCount: Int, maxByteSize: Int64) {
        super.init(maxItemCount: maxItemCount, maxByteSize: maxByteSize)
    }
    
    public override func get(key: Key) -> Value? {
        return self.map[key]
    }
    
    public override func set(key: Key, value: Value) {
        self.map[key] = value
        if let index = sortedKeys.indexOf(key) {
            sortedKeys.removeAtIndex(index)
        }
        sortedKeys.append(key)
    }
    
    public override func contains(key: ItemKey) -> Bool {
        return self.map[key] != nil
    }
    
    public override func removeAll() {
        self.map.removeAll()
        self.sortedKeys.removeAll()
    }
    
    public override func remove(key: Key) -> Value? {
        if let index = sortedKeys.indexOf(key) {
            sortedKeys.removeAtIndex(index)
        }
        return map.removeValueForKey(key)
    }
    
    public override subscript(key: Key) -> Value? {
        get {
            return map[key]
        }
        
        set {
            if newValue != nil {
                self.set(key, value: newValue!)
            } else {
                self.remove(key)
            }
        }
    }
}