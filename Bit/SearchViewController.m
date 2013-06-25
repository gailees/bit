//
//  SearchViewController.m
//  Geolocations
//
//  Created by Héctor Ramos on 8/16/12.
//

#import "SearchViewController.h"
#import "CircleOverlay.h"
#import "GeoPointAnnotation.h"
#import "GeoQueryAnnotation.h"
#import "parseCSV.h"


enum PinAnnotationTypeTag {
    PinAnnotationTypeTagGeoPoint = 0,
    PinAnnotationTypeTagGeoQuery = 1
};

enum segmentedControlIndicies {
    kSegmentStandard = 0,
    kSegmentSatellite = 1,
    kSegmentHybrid = 2,
    kSegmentTerrain = 3
};

@interface SearchViewController ()
- (void)heatMapData;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, assign) CLLocationDistance radius;
@property (nonatomic, strong) CircleOverlay *targetOverlay;
@end

@implementation SearchViewController
@synthesize mapView = _mapView;
@synthesize thumbsUp;
@synthesize thumbsDown;
@synthesize buttonsView;
@synthesize hm;
@synthesize setsOfData;

@synthesize locationManager = _locationManager;
@synthesize currentLocation = _currentLocation;
//@synthesize accountStore = _accountStore;

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"geoPointAnnotiationUpdated" object:nil];
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startLocationManager];
    
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self.locationManager startUpdatingLocation];
    
    // Listen for annotation updates. Triggers a refresh whenever an annotation is dragged and dropped.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadObjects) name:@"geoPointAnnotiationUpdated" object:nil];
    
    self.mapView.region = MKCoordinateRegionMake(self.locationManager.location.coordinate, MKCoordinateSpanMake(0.05f, 0.05f));
    
    PFQuery *query = [PFQuery queryWithClassName:@"ImportedLocations"];
    
    setsOfData = [[NSMutableDictionary alloc] initWithCapacity:[query countObjects]];
    
    [self extendHeatMapData:query n:0];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}


/*
 // Override to customize what kind of query to perform on the class. The default is to query for
 // all objects ordered by createdAt descending.
 - (PFQuery *)queryForTable {
 PFQuery *query = [PFQuery queryWithClassName:self.className];
 
 // If Pull To Refresh is enabled, query against the network by default.
 if (self.pullToRefreshEnabled) {
 query.cachePolicy = kPFCachePolicyNetworkOnly;
 }
 
 // If no objects are loaded in memory, we look to the cache first to fill the table
 // and then subsequently do a query against the network.
 if (self.objects.count == 0) {
 query.cachePolicy = kPFCachePolicyCacheThenNetwork;
 }
 
 [query orderByDescending:@"createdAt"];
 
 return query;
 }
 */



/*
 // Override if you need to change the ordering of objects in the table.
 - (PFObject *)objectAtIndex:(NSIndexPath *)indexPath {
 return [self.objects objectAtIndex:indexPath.row];
 }
 */

/*
 // Override to customize the look of the cell that allows the user to load the next page of objects.
 // The default implementation is a UITableViewCellStyleDefault cell with simple labels.
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
 static NSString *CellIdentifier = @"NextPage";
 
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
 
 if (cell == nil) {
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
 }
 
 cell.selectionStyle = UITableViewCellSelectionStyleNone;
 cell.textLabel.text = @"Load more...";
 
 return cell;
 }
 */


#pragma mark - UITableViewDataSource

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the object from Parse and reload the table view
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, and save it to Parse
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark - MasterViewController

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
    
    if (_locationManager != nil) {
		return _locationManager;
	}
    
	_locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _locationManager.delegate = self;
    
	return _locationManager;
}

- (IBAction)insertCurrentLocation:(id)sender{
    NSNumber *thumb = [NSNumber numberWithBool:true];
    [self insertCurrentLocationWithThumb:sender thumb:thumb];
}

- (IBAction)insertCurrentLocationWithThumb:(id)sender thumb:(NSNumber *)thumb{
	// If it's not possible to get a location, then return.
	CLLocation *location = self.locationManager.location;
	if (!location) {
        NSLog(@"No Location");
		return;
	}
    NSLog(@"YES");
    
	// Configure the new event with information from the location.
	CLLocationCoordinate2D coordinate = [location coordinate];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    NSLog(@"%f",geoPoint.latitude);
    NSLog(@"%f",geoPoint.longitude);
    //NSNumber *thumb = [NSNumber numberWithBool:true];
    
    PFObject *object = [PFObject objectWithClassName:@"Location"];
    
    [object setObject:[NSNumber numberWithBool:thumb] forKey:@"thumb"];
    [object setObject:geoPoint forKey:@"location"];
    
    [object saveInBackground];
    
    //[object saveEventually:^(BOOL succeeded, NSError *error) {
    //}];
}

#pragma mark - MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [[HeatMapView alloc] initWithOverlay:overlay];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    static NSString *GeoPointAnnotationIdentifier = @"RedPinAnnotation";
    static NSString *GeoQueryAnnotationIdentifier = @"PurplePinAnnotation";
    
    if ([annotation isKindOfClass:[GeoQueryAnnotation class]]) {
        MKPinAnnotationView *annotationView =
        (MKPinAnnotationView *)[mapView
                                dequeueReusableAnnotationViewWithIdentifier:GeoQueryAnnotationIdentifier];
        
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc]
                              initWithAnnotation:annotation
                              reuseIdentifier:GeoQueryAnnotationIdentifier];
            annotationView.tag = PinAnnotationTypeTagGeoQuery;
            annotationView.canShowCallout = YES;
            annotationView.pinColor = MKPinAnnotationColorPurple;
            annotationView.animatesDrop = NO;
            annotationView.draggable = YES;
        }
        
        return annotationView;
    } else if ([annotation isKindOfClass:[GeoPointAnnotation class]]) {
        MKPinAnnotationView *annotationView =
        (MKPinAnnotationView *)[mapView
                                dequeueReusableAnnotationViewWithIdentifier:GeoPointAnnotationIdentifier];
        
        if (!annotationView) {
            annotationView = [[MKPinAnnotationView alloc]
                              initWithAnnotation:annotation
                              reuseIdentifier:GeoPointAnnotationIdentifier];
            annotationView.tag = PinAnnotationTypeTagGeoPoint;
            annotationView.canShowCallout = YES;
            annotationView.pinColor = MKPinAnnotationColorRed;
            annotationView.animatesDrop = YES;
            annotationView.draggable = NO;
        }
        
        return annotationView;
    } 
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (![view isKindOfClass:[MKPinAnnotationView class]] || view.tag != PinAnnotationTypeTagGeoQuery) {
        return;
    }
    
    if (MKAnnotationViewDragStateStarting == newState) {
        [self.mapView removeOverlays:self.mapView.overlays];
    } else if (MKAnnotationViewDragStateNone == newState && MKAnnotationViewDragStateEnding == oldState) {
        MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *)view;
        GeoQueryAnnotation *geoQueryAnnotation = (GeoQueryAnnotation *)pinAnnotationView.annotation;
        self.location = [[CLLocation alloc] initWithLatitude:geoQueryAnnotation.coordinate.latitude longitude:geoQueryAnnotation.coordinate.longitude];
        [self configureOverlay];
    }
}

#pragma mark - SearchViewController

- (void)printLocation: (CLLocation *) location {
    if (location) {
        NSLog(@"location!");
        NSLog(@"%f",location.coordinate.latitude);
        NSLog(@"%f",location.coordinate.longitude);
    }
}

- (IBAction)thumbsUp:(id)sender {
    NSLog(@"%@", self.locationManager.location);
    [self insertCurrentLocationWithThumb:sender thumb:[NSNumber numberWithBool:true]];
    //[thumbsUp setHidden:TRUE];
    //[self configureOverlay];
    [buttonsView setHidden:TRUE];
}

- (IBAction)thumbsDown:(id)sender {
    [self insertCurrentLocationWithThumb:sender thumb:[NSNumber numberWithBool:false]];
    //[thumbsDown setHidden:TRUE];
    [buttonsView setHidden:TRUE];
    //[self configureOverlay];
}

- (void)setInitialLocation:(CLLocation *)aLocation {
    self.location = aLocation;
    self.radius = 1000;
}

#pragma mark - ()

- (IBAction)sliderDidTouchUp:(UISlider *)aSlider {
    if (self.targetOverlay) {
        [self.mapView removeOverlay:self.targetOverlay];
    }

    [self configureOverlay];
}

- (IBAction)sliderValueChanged:(UISlider *)aSlider {
    self.radius = aSlider.value;
    
    if (self.targetOverlay) {
        [self.mapView removeOverlay:self.targetOverlay];
    }

    self.targetOverlay = [[CircleOverlay alloc] initWithCoordinate:self.location.coordinate radius:self.radius];
    [self.mapView addOverlay:self.targetOverlay];
}

- (void)configureOverlay {
    
    //HeatMap *hm = [[HeatMap alloc] initWithData:[self heatMapData]];
    [self.mapView addOverlay:hm];
    [self.mapView setVisibleMapRect:[hm boundingMapRect] animated:YES];

/*
    NSLog(@"%@", self.location);
    if (self.location) {
        [self.mapView removeAnnotations:self.mapView.annotations];
        [self.mapView removeOverlays:self.mapView.overlays];
        
        CircleOverlay *overlay = [[CircleOverlay alloc] initWithCoordinate:self.location.coordinate radius:self.radius];
        [self.mapView addOverlay:overlay];
        
        GeoQueryAnnotation *annotation = [[GeoQueryAnnotation alloc] initWithCoordinate:self.location.coordinate radius:self.radius];
        [self.mapView addAnnotation:annotation];
        
        [self updateLocations];
    }
*/
}

- (void)updateLocations {
    CGFloat kilometers = self.radius/1000.0f;

    PFQuery *query = [PFQuery queryWithClassName:@"Location"];
    [query setLimit:1000];
    [query whereKey:@"location"
       nearGeoPoint:[PFGeoPoint geoPointWithLatitude:self.location.coordinate.latitude
                                           longitude:self.location.coordinate.longitude]
   withinKilometers:kilometers];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *object in objects) {
                GeoPointAnnotation *geoPointAnnotation = [[GeoPointAnnotation alloc]
                                                          initWithObject:object];
                [self.mapView addAnnotation:geoPointAnnotation];
            }
        }
    }];
}

- (void)printObjects:(NSMutableArray *)blah{
    NSLog(@"%@", [blah objectAtIndex:0]);
    NSLog(@"next");
}

- (void)viewDidUnload {
    [self setThumbsUp:nil];
    [self setThumbsDown:nil];
    [super viewDidUnload];
}

#pragma mark - CLLocationManagerDelegate

/**
 Conditionally enable the Search/Add buttons:
 If the location manager is generating updates, then enable the buttons;
 If the location manager is failing, then disable the buttons.
 */
- (void)startLocationManager {
    if( !_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = 100;
        _locationManager.delegate = self;
    }
    
    [_locationManager startUpdatingLocation];

}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    NSLog(@"latitude %+.6f, longitude %+.6f accuracy %1.2f time %d",
          newLocation.coordinate.latitude,
          newLocation.coordinate.longitude, newLocation.horizontalAccuracy, abs([newLocation.timestamp timeIntervalSinceNow]));
    
    [self.mapView setRegion:MKCoordinateRegionMake(
                                                   CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude),
                                                   MKCoordinateSpanMake(0.01, 0.01)
                                                   )];
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 10.0) return;
    
    if (newLocation.horizontalAccuracy < 0) return;
    
    if (self.currentLocation == nil && newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy)
    {
        self.currentLocation = newLocation;
        
        [self printLocation:newLocation];
        
        [self stopLocationManager];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    if ( [error code] != kCLErrorLocationUnknown){
        [self printLocation:nil];
        [self stopLocationManager];
    }
    
}

- (void)stopLocationManager{
    [self.locationManager stopUpdatingLocation];
}

- (void)heatMapData
{

}

- (void) extendHeatMapData:(PFQuery *)query n:(int)n{
    //NSLog(@"%ld", (long)[query countObjects]);
    if( n == 100){
        [self configureOverlay];
    }
    if(n >= [query countObjects]){
        [self configureOverlay];
        return;
    }
    [query setLimit:100];
    query.skip = n;
    NSMutableDictionary *toRet = [[NSMutableDictionary alloc] initWithCapacity:100];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            for (PFObject *object in objects) {
                PFGeoPoint *location = [object objectForKey:@"location"];
                //NSLog(@"%f", location.latitude);
                //NSLog(@"%f", location.longitude);
                
                MKMapPoint point = MKMapPointForCoordinate(
                                                           CLLocationCoordinate2DMake(
                                                                                      location.latitude,
                                                                                      location.longitude));
                
                NSValue *pointValue = [NSValue value:&point withObjCType:@encode(MKMapPoint)];
                if ([object objectForKey:@"thumb"]){
                    [toRet setObject:[NSNumber numberWithDouble:0.2] forKey:pointValue];
                }
            }
            //HeatMap *hm = [[HeatMap alloc] initWithData:toRet];
            //[self.mapView addOverlay:hm];
            //[self.mapView setVisibleMapRect:[hm boundingMapRect] animated:YES];
        }
        else {
            NSLog(@"error");
        }
        NSLog(@"heatmap ready");
        [setsOfData addEntriesFromDictionary:toRet];
        hm = [[HeatMap alloc] initWithData:setsOfData];
        [self extendHeatMapData:query n:(n+100)];
    }];
    NSLog(@"done heatmap extension");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [buttonsView setHidden:false];
}
     
@end
