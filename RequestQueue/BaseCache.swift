//
//  ELSBaseCache.swift
//  ELSQueue
//
//  Created by Jamse Li on 10/10/15.
//  Copyright © 2015 eLivingStore. All rights reserved.
//

import Foundation

/**
A base class of Cache, it's not intended to be used in production env. You need to write a subclass for it.
*/
public class BaseCache<Key: Hashable, Value> : Cache {
    public typealias ItemKey = Key
    public typealias ItemValue = Value
    
    var innerMaxItemCount: Int
    var innerMaxByteSize: Int64
    
    public var maxItemCount: Int {
        get {
            return self.innerMaxItemCount
        }
        set {
            self.innerMaxItemCount = newValue
        }
    }
    
    public var maxByteSize: Int64 {
        get {
            return self.innerMaxByteSize
        }
        
        set {
            self.innerMaxByteSize = newValue
        }
    }
    
    public required init(maxItemCount: Int, maxByteSize: Int64) {
        self.innerMaxItemCount = maxItemCount
        self.innerMaxByteSize = maxByteSize
    }
    
    public func get(key: Key) -> Value? {
        return nil
    }
    
    public func set(key: Key, value: Value) {
    }
    
    public func contains(key: ItemKey) -> Bool {
        return false
    }
    
    public func removeAll() {
    }
    
    public func remove(key: Key) -> Value? {
        return nil
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return nil
        }
        
        set {
        }
    }
}