//
//  SPTRDatabaseController.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface SPTRDatabaseController : NSObject

+ (SPTRDatabaseController *)sharedInstance;
- (NSMutableArray *)getAllGarages;

@property (strong) FMDatabase * database;

@end
