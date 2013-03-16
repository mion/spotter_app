//
//  SPTRViewController.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/25/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MBProgressHUD.h"

@interface SPTRViewController : UIViewController <MKMapViewDelegate, MBProgressHUDDelegate>

- (void)hideProgressHUD:(BOOL)syncSuccessful;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (atomic, retain) MBProgressHUD *HUD;

@end
