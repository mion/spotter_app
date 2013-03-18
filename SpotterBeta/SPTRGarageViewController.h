//
//  SPTRGarageViewController.h
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 3/17/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "SPTRGarage.h"

@interface SPTRGarageViewController : UIViewController <MKMapViewDelegate>

@property (atomic, retain) SPTRGarage *garage;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *openingLabel;

- (IBAction)directionsButtonClicked:(id)sender;
@end
