//
//  SPTRDatabaseController.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRDatabaseController.h"
#import "SPTRGarage.h"

static NSString * const kSPTRDatabaseName = @"sptr";

@implementation SPTRDatabaseController

@synthesize databaseQueue;

+ (SPTRDatabaseController *)sharedInstance
{
    static SPTRDatabaseController *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPTRDatabaseController alloc] init];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = [paths objectAtIndex:0];
        
        NSString *dbPath = [documentsDir stringByAppendingPathComponent:@"sptr.sqlite3"];
        NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:@"sptr" ofType: @"sqlite3"];
        
        if ([fileManager fileExistsAtPath:dbPath] == NO)
        {
            BOOL success = [fileManager copyItemAtPath:defaultDBPath toPath:dbPath error:&error];
            
            //NSLog(@"defaultDBPath: %@", defaultDBPath);
            //NSLog(@"dbPath: %@", dbPath);
            
            if(!success){
                NSLog(@"Failed to create writable database file with message '%@'.", [error localizedDescription]);
            }
        }
        
        sharedInstance.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    });
    
    return sharedInstance;
}

- (NSMutableArray *)getAllGarages
{
    NSMutableArray *garages = [[NSMutableArray alloc] init];
    FMDatabaseQueue *queue = self.databaseQueue;
    
    [queue inDatabase:^(FMDatabase *db) {        
        FMResultSet *s = [db executeQuery:@"SELECT * FROM garage"];
        
        while ([s next]) {
            SPTRGarage* g = [[SPTRGarage alloc] init];
            
            g.address = [s stringForColumn:@"address"];
            g.created_at = [s stringForColumn:@"created_at"];
            g.updated_at = [s stringForColumn:@"updated_at"];
            g.primaryKey = [s intForColumn:@"id"];
            g.latitude = [ NSNumber numberWithDouble:[s doubleForColumn:@"latitude"]];
            g.longitude = [ NSNumber numberWithDouble:[s doubleForColumn:@"longitude"]];
            g.name = [s stringForColumn:@"name"];
            g.opening = [s stringForColumn:@"opening"];
            g.phone = [s stringForColumn:@"phone"];
            
            [garages addObject:g];
        }
        
        [s close];
    }];
    
    return garages;
}

- (void)saveResponseArray:(NSArray *)responseArray {
    FMDatabaseQueue * queue = self.databaseQueue;
        
    if ([responseArray count] == 0)
    {
        return;
    }
    
    [queue inDatabase:^(FMDatabase *db) {
        for (uint i = 0; i < [responseArray count]; i++)
        {
            NSDictionary * response = [responseArray objectAtIndex:i];
            
            if( ![db executeUpdate:@"INSERT INTO garage VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
             response[@"address"],
             response[@"created_at"],
             response[@"updated_at"],
             response[@"id"],
             response[@"latitude"],
             response[@"longitude"],
             response[@"name"],
             response[@"opening"],
             response[@"phone"]])
            {
                // TODO: Handle error.
                NSLog(@"FMDB Error: unable to execute update.");
                NSLog(@"Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                return;
            }
        }
    }];
    
    NSLog(@"Response saved to database!");
}

- (NSString *)getMostRecentUpdatedAtDate {
    __block NSString * date = nil;
    
    FMDatabaseQueue *queue = self.databaseQueue;
    
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *s = [db executeQuery:@"SELECT updated_at FROM garage ORDER BY julianday(updated_at) DESC;"];
        
        // TODO: check for errors
        
        if ([s next])
        {
            date = [s stringForColumn:@"updated_at"];
            NSLog(@"Most recent updated: %@", [s stringForColumn:@"updated_at"]);
        }
        
        [s close];
    }];
    
    return date;
}

@end
