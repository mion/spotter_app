//
//  SPTRAFSpotterAPIClient.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRAFSpotterAPIClient.h"
#import "AFJSONRequestOperation.h"

static NSString * const kSPTRSpotterAPIBaseURLString = @"http://aqueous-citadel-6834.herokuapp.com";

@implementation SPTRAFSpotterAPIClient

+ (SPTRAFSpotterAPIClient *)sharedClient
{
    static SPTRAFSpotterAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[SPTRAFSpotterAPIClient alloc] initWithBaseURL:[NSURL URLWithString:kSPTRSpotterAPIBaseURLString]];
    });
    
    return sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self)
    {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setParameterEncoding:AFJSONParameterEncoding];
        //[self setDefaultHeader:@"X-Parse-Application-Id" value:kSDFParseAPIApplicationId];
        //[self setDefaultHeader:@"X-Parse-REST-API-Key" value:kSDFParseAPIKey];
    }
    
    return self;
}

- (NSURLRequest *)GETRequestForGaragesUpdatedAfterDate:(NSString *) updatedDate
{
    NSString * updatedAfter = updatedDate ? [NSString stringWithFormat:@"/?updated_after=%@", updatedDate] : @"" ;
    
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/garages.json%@", kSPTRSpotterAPIBaseURLString, updatedAfter]];
    NSLog(@"API - Sending request to: %@", [NSString stringWithFormat:@"%@/garages.json%@", kSPTRSpotterAPIBaseURLString, updatedAfter]);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    return request;
}

@end
