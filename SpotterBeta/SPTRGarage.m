//
//  SPTRGarage.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRGarage.h"
#import <AddressBook/AddressBook.h>

@implementation SPTRGarage

@synthesize primaryKey;
@synthesize name;
@synthesize address;
@synthesize phone;
@synthesize opening;
@synthesize latitude;
@synthesize longitude;
@synthesize created_at;
@synthesize updated_at;

-(NSString *)title {
    return name;
}

-(NSString *)subtitle {
    return address;
}

-(CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D c;
    c.latitude = [latitude doubleValue];
    c.longitude = [longitude doubleValue];
    return c;
}

-(MKMapItem *)mapItem {
    NSDictionary *addressDict = @{(NSString*)kABPersonAddressStreetKey : address};
    
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = self.title;
    
    return mapItem;
}

@end
