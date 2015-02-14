//
//  FeedItem.swift
//  Wub
//
//  Created by User  on 2015-01-13.
//  Copyright (c) 2015 Wub.com. All rights reserved.
//

import Foundation
import CoreData


@objc (FeedItem)
class FeedItem: NSManagedObject {
    
    @NSManaged var caption: String
    @NSManaged var image: NSData
    @NSManaged var thumbNail: NSData
    @NSManaged var cdate: NSTimeInterval
    
}
