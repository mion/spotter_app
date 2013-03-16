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

@synthesize database;

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
        
        sharedInstance.database = [FMDatabase databaseWithPath:dbPath];
    });
    
    return sharedInstance;
}

- (NSMutableArray *)getAllGarages
{
    NSMutableArray *garages = [[NSMutableArray alloc] init];
    FMDatabase *db = self.database;
    FMResultSet *s;
    
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
    
    return garages;
}

@end
