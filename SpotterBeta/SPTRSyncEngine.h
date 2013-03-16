//
//  SPTRSyncEngine.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPTRViewController.h"

@interface SPTRSyncEngine : NSObject

+ (SPTRSyncEngine *)sharedEngine;
- (void)startSync:(SPTRViewController *)viewController;

@property (atomic, readonly) BOOL syncInProgress;

@end
