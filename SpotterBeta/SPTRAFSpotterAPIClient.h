//
//  SPTRAFSpotterAPIClient.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/30/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "AFHTTPClient.h"

@interface SPTRAFSpotterAPIClient : AFHTTPClient

+ (SPTRAFSpotterAPIClient *)sharedClient;
- (NSURLRequest *)GETRequestForGaragesUpdatedAfterDate:(NSString *) updatedDate;

@end
