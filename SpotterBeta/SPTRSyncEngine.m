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

- (void)writeJSONResponse:(id)responseObject
{
    NSArray * responseArray = responseObject;
    SPTRGarage * garage = [[SPTRGarage alloc] init];
    FMDatabase * db = [SPTRDatabaseController sharedInstance].database; // TODO: Refactor (getDatabase ?)
    
    NSLog(@"JSON: %@", responseObject);
    
    if ([responseArray count] == 0)
    {
        return;
    }
    
    if (![db open])
    {
        // TODO: Handle error.
        // Opening fails if there are insufficient resources or permissions to open and/or create the database.
        NSLog(@"FMDB Error: unable to open database.");
        return;
    }
    
    for (uint i = 0; i < [responseArray count]; i++)
    {
        NSDictionary * response = [responseArray objectAtIndex:i];
        
        garage.primaryKey = response[@"id"];
        
        garage.address = response[@"address"];
        garage.created_at = response[@"created_at"];
        garage.updated_at = response[@"updated_at"];
        
        garage.latitude = response[@"latitude"];
        garage.longitude = response[@"longitude"];
        garage.name = response[@"name"];
        garage.opening = response[@"opening"];
        garage.phone = response[@"phone"];
        
        if (![db executeUpdate:@"INSERT INTO garage VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
              garage.address,
              garage.created_at,
              garage.updated_at,
              garage.primaryKey,
              garage.latitude,
              garage.longitude,
              garage.name,
              garage.opening,
              garage.phone])
        {
            // TODO: Handle error.
            NSLog(@"FMDB Error: unable to execute update.");
            NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
            [db close];
            return;
        }
    }
    
    [db close];
    
    NSLog(@"Response saved to database!");
}

- (NSString *)mostRecentUpdatedAtDate
{
    NSString * date = nil;
    FMDatabase * db = [SPTRDatabaseController sharedInstance].database; // TODO: Refactor (getDatabase ?)
    FMResultSet * s;
    
    if (![db open])
    {
        // TODO: Handle error.
        // Opening fails if there are insufficient resources or permissions to open and/or create the database.
        NSLog(@"FMDB Error: unable to open database.");
        return nil;
    }
    
    s = [db executeQuery:@"SELECT updated_at FROM garage ORDER BY julianday(updated_at) DESC;"];
    
    if (!s)
    {
        // TODO: Handle error.
        NSLog(@"FMDB Error: unable to execute query.");
        NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        [db close];
        return nil;
    }
    
    if ([s next])
    {
        date = [s stringForColumn:@"updated_at"];
        NSLog(@"Most recent updated: %@", [s stringForColumn:@"updated_at"]);
    }
    
    [db close];
    
    return date;
}

- (void)downloadData:(BOOL)useUpdatedAtDate
{
    NSURLRequest *request = nil;
    NSString * mostRecentUpdatedDate = nil;
    
    if (useUpdatedAtDate)
    {
        mostRecentUpdatedDate = [self mostRecentUpdatedAtDate];
    }
    
    request = [[SPTRAFSpotterAPIClient sharedClient] GETRequestForGaragesUpdatedAfterDate:mostRecentUpdatedDate];
    
    AFHTTPRequestOperation *operation = [[SPTRAFSpotterAPIClient sharedClient] HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Response %@", responseObject);
        [self writeJSONResponse:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error);
    }];
    
    [operation start];
}

- (void)startSync
{
    if (!self.syncInProgress)
    {
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        [self didChangeValueForKey:@"syncInProgress"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self downloadData:YES];
        });
    }
}

@end
