//
//  SPTRSyncEngine.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRSyncEngine.h"
#import "SPTRAFSpotterAPIClient.h"
#import "AFHTTPRequestOperation.h"
#import "SPTRDatabaseController.h"
#import "SPTRGarage.h"

@implementation SPTRSyncEngine

NSString * const kSPTRSyncEngineInitialCompleteKey = @"SPTRSyncEngineInitialSyncCompleted";
NSString * const kSPTRSyncEngineSyncCompletedNotificationName = @"SPTRSyncEngineSyncCompleted";

@synthesize syncInProgress = _syncInProgress;

+ (SPTRSyncEngine *)sharedEngine
{
    static SPTRSyncEngine *sharedEngine = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[SPTRSyncEngine alloc] init];
    });
    
    return sharedEngine;
}

- (BOOL)initialSyncComplete {
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSPTRSyncEngineInitialCompleteKey] boolValue];
}

- (void)setInitialSyncCompleted {
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kSPTRSyncEngineInitialCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)executeSyncCompletedOperations {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setInitialSyncCompleted];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kSPTRSyncEngineSyncCompletedNotificationName
         object:nil];
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = NO;
        [self didChangeValueForKey:@"syncInProgress"];
    });
}

- (void)writeJSONResponse:(id)responseObject // REFACTOR: put db code in the DatabaseController
{
    NSArray * responseArray = responseObject;
    NSLog(@"API - Response JSON: %@", responseObject);
    
    [[SPTRDatabaseController sharedInstance] saveResponseArray:responseArray];
}

- (NSString *)mostRecentUpdatedAtDate
{
    return [[SPTRDatabaseController sharedInstance] getMostRecentUpdatedAtDate];
}

- (void)downloadData:(BOOL)useUpdatedAtDate updateViewController:(SPTRViewController *)viewController
{
    NSURLRequest *request = nil;
    NSString * mostRecentUpdatedDate = nil;
    
    if (useUpdatedAtDate)
    {
        mostRecentUpdatedDate = [self mostRecentUpdatedAtDate];
    }
    
    request = [[SPTRAFSpotterAPIClient sharedClient] GETRequestForGaragesUpdatedAfterDate:mostRecentUpdatedDate];
    
    if (viewController == NULL) { // REFACTOR? duplicated code
        AFHTTPRequestOperation *operation = [[SPTRAFSpotterAPIClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self writeJSONResponse:responseObject];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Request failed with error: %@", error); // TODO: use service to log this error
        }];
        [operation start];
    } else {        
        AFHTTPRequestOperation *operation = [[SPTRAFSpotterAPIClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self writeJSONResponse:responseObject];
            [viewController hideProgressHUD:YES];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [viewController hideProgressHUD:NO];
            NSLog(@"Request failed with error: %@", error); // TODO: use service to log this error
        }];
        [operation start];
    }
}

- (void)startSync:(SPTRViewController *)viewController
{
    if (!self.syncInProgress)
    {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadData:YES updateViewController:viewController];
        });
    }
}

@end
