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
#import "SPTRAFSpotterAPIClient.h"

#define METERS_PER_MILE 1609.344

@interface SPTRViewController ()

@end

@implementation SPTRViewController

@synthesize addressSearchBar;
@synthesize HUD;

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
        
        [self showHUDwithLabel:@"Por favor, aguarde..." withDetails:@"Atualizando estacionamentos"];
        
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

# pragma mark - Map
- (void)setupMapAndPlotGarages
{
    NSLog(@"Plotting garages...");
    CLLocationCoordinate2D zoomLocation; // TODO: show current location
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

-(void)updateMapViewAfterAddressSearchWithResults:(NSArray *)response
{
    CLLocationCoordinate2D zoomLocation;
    
    if ([response count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Busca sem resultados"
                                                        message:@"Não há nenhum estacionamento próximo a este endereço."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    for (uint i = 0; i < [response count]; i++)
    {
        NSDictionary * garage = [response objectAtIndex:i];
        
        if (i == 0)
        {
            zoomLocation.latitude = [garage[@"latitude"] doubleValue];
            zoomLocation.longitude = [garage[@"longitude"] doubleValue];
        }
    }
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    
    [_mapView setRegion:viewRegion animated:YES];
}

# pragma mark - Search
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //Perform the JSON query.
    NSLog(@"Searching: %@", [searchBar text]);
    [self searchNearby:[searchBar text] within:@"0.6"];
    
    //Hide the keyboard.
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchNearby:(NSString *)address within:(NSString *)miles
{
    [self showHUDwithLabel:@"Por favor, aguarde..." withDetails:@"Procurando endereço"];
    
    [[SPTRAFSpotterAPIClient sharedClient] findGaragesNear:address within:miles withSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"API - Garages near JSON: %@", responseObject);
        [HUD hide:YES];
        
        NSArray *results = responseObject;
        [self updateMapViewAfterAddressSearchWithResults:results];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Request failed with error: %@", error); // TODO: use service to log this error
        [HUD hide:YES];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sem conexão com a internet"
                                                        message:@"Certifique-se de que você está conectado à internet para buscar um endereço."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }];
}

# pragma mark - ProgressHUD
- (void)firstTimeSyncCompleted:(BOOL)syncSuccessful
{
    [HUD hide:YES];
    
    if (!syncSuccessful) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sem conexão com a internet"
                                                        message:@"Certifique-se de que você está conectado à internet e reinicie o aplicativo."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        [self setupMapAndPlotGarages]; // REFACTOR: should this be called from here? kidna weird
    }
}

-(void)showHUDwithLabel:(NSString *)labelText withDetails:(NSString *)detailsLabelText
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    HUD.labelText = labelText;
    HUD.detailsLabelText = detailsLabelText;
    HUD.square = YES;
    
    HUD.delegate = self;
}

@end
