//
//  FeedItem.swift
//  Wub
//
//  Created by User  on 2015-02-16.
//  Copyright (c) 2015 Wub.com. All rights reserved.
//

import Foundation
import CoreData


@objc(FeedItem)
class FeedItem: NSManagedObject {

    @NSManaged var caption: String
    @NSManaged var cdate: NSNumber
    @NSManaged var image: NSData
    @NSManaged var thumbNail: NSData
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var uniqueID: String
    @NSManaged var filtered: NSNumber

}
