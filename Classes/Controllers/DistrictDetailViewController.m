//
//  DistrictDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "DistrictDetailViewController.h"
#import "LegislatorDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFRestKitManager.h"
#import "SLFTheme.h"
#import "SLFAlertView.h"
#import "DistrictPinAnnotationView.h"
#import "DistrictSearch.h"

@interface DistrictDetailViewController()
- (void)loadMapWithID:(NSString *)objID;
- (void)loadDataWithResourcePath:(NSString *)path;
- (BOOL)isUpperDistrictWithID:(NSString *)objID;
- (BOOL)isUpperDistrict:(SLFDistrict *)obj;
- (void)setUpperOrLowerDistrict:(SLFDistrict *)districtMap;
@property (nonatomic,retain) DistrictSearch *districtSearch;
@end

@implementation DistrictDetailViewController
@synthesize resourceClass;
@synthesize upperDistrict;
@synthesize lowerDistrict;
@synthesize districtSearch;

- (id)initWithDistrictMapID:(NSString *)objID {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.resourceClass = [SLFDistrict class];
        [self loadMapWithID:objID];
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.upperDistrict = nil;
    self.lowerDistrict = nil;
    self.districtSearch = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)loadMapWithID:(NSString *)objID {
    if (IsEmpty(objID))
        return;
    SLFDistrict *district = [SLFDistrict findFirstByAttribute:@"boundaryID" withValue:objID];
    if (district)
        [self setUpperOrLowerDistrict:district];
    [self loadDataWithResourcePath:[NSString stringWithFormat:@"/districts/boundary/%@", objID]];    // DON'T REALLY LOAD UNLESS WE HAVE TO
}

- (void)setUpperOrLowerDistrict:(SLFDistrict *)newObj {
    if (!newObj)
        return;
    if ([self isUpperDistrict:newObj])
        self.upperDistrict = newObj;
    else
        self.lowerDistrict = newObj;
}

- (void)loadDataWithResourcePath:(NSString *)path {
    if (IsEmpty(path))
        return;    
    NSDictionary *queryParameters = [NSDictionary dictionaryWithObject:SUNLIGHT_APIKEY forKey:@"apikey"];
    NSString *pathToLoad = [path appendQueryParams:queryParameters];
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:pathToLoad delegate:self];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {    
    if (!object || ![object isKindOfClass:self.resourceClass])
        return;
    SLFDistrict *district = object;
    [self setUpperOrLowerDistrict:district];

    if (![self isViewLoaded])
        return;
    [self.mapView addAnnotation:district];
    [self moveMapToRegion:district.region];
    MKPolygon *polygon = [district polygonFactory];
    if (polygon)
        [self.mapView addOverlay:polygon];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (SLFDistrict *)districtMapForPolygon:(MKPolygon *)polygon {
    if (!polygon)
        return nil;
    NSString *boundaryID = [polygon subtitle];
    if (IsEmpty(boundaryID)) {
        if (self.upperDistrict && polygon.pointCount == self.upperDistrict.polygonFactory.pointCount)
            return self.upperDistrict;
        return self.lowerDistrict;
    }
    return [SLFDistrict findFirstByAttribute:@"boundaryID" withValue:boundaryID];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        SLFDistrict *district = [self districtMapForPolygon:(MKPolygon*)overlay];
        MKPolygonView *aView = [[[MKPolygonView alloc] initWithPolygon:(MKPolygon*)overlay] autorelease];
        if (district && [self isUpperDistrict:district])
            aView.fillColor = [[UIColor orangeColor] colorWithAlphaComponent:0.2];
        else 
            aView.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
        aView.strokeColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
        aView.lineWidth = 2;
        return aView;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation {    
    if ([annotation isKindOfClass:self.resourceClass])
    {
        SLFDistrict *district = annotation;
        DistrictPinAnnotationView *pinView = (DistrictPinAnnotationView*)[aMapView dequeueReusableAnnotationViewWithIdentifier:DistrictPinAnnotationViewReuseIdentifier];
        if (!pinView)
            pinView = [DistrictPinAnnotationView districtPinViewWithAnnotation:district identifier:DistrictPinAnnotationViewReuseIdentifier];
        else
            pinView.annotation = district;
        [pinView setPinColorWithAnnotation:annotation];
        if ([district.legislators count] == 1) { 
            [pinView enableAccessory];
        }
        return pinView;
    }
    return [super mapView:aMapView viewForAnnotation:annotation];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView {
    if (aView && [aView isSelected] && [aView isKindOfClass:[DistrictPinAnnotationView class]])
        self.selectedAnnotationView = aView;
    [super mapView:mapView didSelectAnnotationView:aView];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView calloutAccessoryControlTapped:(UIControl *)control {
    if (annotationView && [annotationView isKindOfClass:[DistrictPinAnnotationView class]]) {
        SLFDistrict *district = annotationView.annotation;
        if (!district)
            return;
        if (district.legislators && [district.legislators count] == 1) {
            SLFLegislator *leg = [district.legislators anyObject];
            if (leg && leg.legID) {
                LegislatorDetailViewController *vc = [[LegislatorDetailViewController alloc] initWithLegislatorID:leg.legID];
                [self stackOrPushViewController:vc];
                [vc release];
            }    
        }
        return;
    }
}

- (void)beginBoundarySearchForCoordininate:(CLLocationCoordinate2D)coordinate {
    self.districtSearch = [DistrictSearch districtSearchForCoordinate:coordinate 
                                             successBlock:^(NSArray *results) {
                                                 for (NSString *districtID in results)
                                                     [self loadMapWithID:districtID];
                                                 self.districtSearch = nil;
                                             }
                                             failureBlock:^(NSString *message, DistrictSearchFailOption failOption) {
                                                 if (failOption == DistrictSearchFailOptionLog)
                                                     RKLogError(@"%@", message);
                                                 else
                                                     [SLFAlertView showWithTitle:NSLocalizedString(@"Geolocation Error", @"") message:message buttonTitle:NSLocalizedString(@"OK", @"")];
                                                 self.districtSearch = nil;
                                             }];
}

- (BOOL)isUpperDistrictWithID:(NSString *)objID {
    if (!IsEmpty(objID) && [objID hasPrefix:@"sldu"])
        return YES;
    return NO;
}

- (BOOL)isUpperDistrict:(SLFDistrict *)obj {
    if ([self isUpperDistrictWithID:obj.boundaryID] || [obj.chamberObj.type isEqualToString:@"upper"])
        return YES;
    return NO;
}
@end
