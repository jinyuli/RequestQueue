//
//  ELSCache.swift
//  ELSQueue
//
//  Created by Jamse Li on 10/10/15.
//  Copyright © 2015 eLivingStore. All rights reserved.
//

import Foundation

public protocol Cache {
    typealias ItemKey
    typealias ItemValue
    
    var maxItemCount: Int{get}
    var maxByteSize: Int64{get}
    
    func get(key: ItemKey) -> ItemValue?
    func set(key: ItemKey, value: ItemValue)
    func contains(key: ItemKey) -> Bool
    func remove(key: ItemKey) -> ItemValue?
    func removeAll()
}