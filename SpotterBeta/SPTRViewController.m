//
//  SPTRViewController.m
//  SpotterBeta
//
//  Created by Gabriel Luis Vieira on 1/25/13.
//  Copyright (c) 2013 Spotter. All rights reserved.
//

#import "SPTRViewController.h"
#import "SPTRDatabaseController.h"
#import "SPTRGarage.h"
#import "SPTRSyncEngine.h"

#define METERS_PER_MILE 1609.344

@interface SPTRViewController ()

@end

@implementation SPTRViewController

@synthesize HUD;
@synthesize searchBar;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    // Check for updates on the server.
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"]) {
        // If it's the first time, show a progress bar.
        NSLog(@"First time sync started!");
        
        HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        HUD.labelText = @"Por favor, aguarde...";
        HUD.detailsLabelText = @"Atualizando estacionamentos";
        HUD.square = YES;
        
        HUD.delegate = self;
        
        [[SPTRSyncEngine sharedEngine] startSync:self];
    } else {
        NSLog(@"Sync started.");
        [[SPTRSyncEngine sharedEngine] startSync:NULL];
        [self setupMapAndPlotGarages];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupMapAndPlotGarages
{
    NSLog(@"Plotting garages...");
    CLLocationCoordinate2D zoomLocation;
    zoomLocation.latitude = -22.9858472;
    zoomLocation.longitude = -43.2143279;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    
    [_mapView setRegion:viewRegion animated:YES];
    
    for (id<MKAnnotation> annotation in _mapView.annotations) {
        [_mapView removeAnnotation:annotation];
    }
    
    NSMutableArray *data = [[SPTRDatabaseController sharedInstance] getAllGarages];
    
    for (SPTRGarage *garage in data) {
        [_mapView addAnnotation:garage];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"SPTRGarage";
    if ([annotation isKindOfClass:[SPTRGarage class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"spotter_pin.png"];
            
            UIButton * disclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            annotationView.rightCalloutAccessoryView = disclosureButton;
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    SPTRGarage *garage = (SPTRGarage *)view.annotation;
    
    NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
    [garage.mapItem openInMapsWithLaunchOptions:launchOptions];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    NSLog(@"Searching address: %@", [theSearchBar text]);
    [theSearchBar resignFirstResponder];
}

- (void)hideProgressHUD:(BOOL)syncSuccessful {
    [HUD hide:YES];
    
    if (!syncSuccessful) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sem conexão com a internet"
                                                        message:@"Certifique-se de que você está conectado à internet e reinicie o aplicativo."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        [self setupMapAndPlotGarages];
    }
}

@end
