//
//  SPTRViewController.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/25/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"
#import "SPTRGarage.h"

@interface SPTRViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, MBProgressHUDDelegate>
{
    CLLocationManager *locationManager;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchUIBarButtonItem;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property IBOutlet UISearchBar *addressSearchBar;
@property (atomic, retain) MBProgressHUD *HUD;
@property (atomic, retain) SPTRGarage *segueGarage; // needed to pass garage to segue, called from mapview callback

- (void)firstTimeSyncCompleted:(BOOL)syncSuccessful;
- (IBAction)searchBarButtonClicked:(id)sender;
@end
