//
//  SPTRGarageViewController.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 3/17/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRGarageViewController.h"
#import "SPTRGarage.h"

@implementation SPTRGarageViewController

@synthesize garage;

- (void)viewWillAppear:(BOOL)animated
{
    [_nameLabel setText:garage.name];
    [_phoneLabel setText:garage.phone];
    [_addressLabel setText:garage.address];
    [_openingLabel setText:garage.opening];
    
    for (id<MKAnnotation> annotation in _mapView.annotations) {
        [_mapView removeAnnotation:annotation];
    }
    
    [_mapView addAnnotation:garage];
    
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = [garage.latitude doubleValue];
    zoomLocation.longitude = [garage.longitude doubleValue];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(zoomLocation, 300, 300);
    [_mapView setRegion:region animated:NO];
}

- (IBAction)directionsButtonClicked:(id)sender {
    //SPTRGarage *garage = (SPTRGarage *)view.annotation;

    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    [garage.mapItem openInMapsWithLaunchOptions:launchOptions];
}
@end
