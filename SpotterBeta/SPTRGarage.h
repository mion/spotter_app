//
//  SPTRGarage.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface SPTRGarage : NSObject <MKAnnotation>

- (MKMapItem *)mapItem;

@property (atomic, retain) NSString * address;
@property (atomic, retain) NSString * created_at;
@property (atomic, retain) NSString * updated_at;
@property (atomic) int primaryKey;
@property (atomic, retain) NSNumber * latitude;
@property (atomic, retain) NSNumber * longitude;
@property (atomic, retain) NSString * name;
@property (atomic, retain) NSString * opening;
@property (atomic, retain) NSString * phone;

@end
