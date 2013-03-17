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
    }];
    
    /*
    if(![db open])
    {
        // TODO: Handle error.
        NSLog(@"FMDB Error: unable to open database.");
        return nil;
    }
    
    s = [db executeQuery:@"SELECT * FROM garage"];
    
    if (!s)
    {
        // TODO: Handle error.
        NSLog(@"FMDB Error: unable to execute query.");
        [db close];
        return nil;
    }
    
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
    
    [db close];
    */
    
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
                [db close];
                return;
            }
        }
    }];
    
    /*
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
    */
    
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
    }];
    
    /*
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
     */
    
    return date;
}

@end
