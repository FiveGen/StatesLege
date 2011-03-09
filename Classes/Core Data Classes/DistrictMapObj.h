//
//  DistrictMapObj.h
//  TexLege
//
//  Created by Gregory Combs on 8/21/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "TexLegeDataObjectProtocol.h"

#import <MapKit/MapKit.h>

@class LegislatorObj;

@interface DistrictMapObj :  RKManagedObject  <NSCoding, MKAnnotation>
{
	NSNumber * districtMapID;
	NSNumber * chamber;
	NSNumber * centerLon;
	NSNumber * spanLat;
	NSNumber * lineWidth;
	NSData * coordinatesData;
	NSNumber * numberOfCoords;
	NSNumber * maxLat;
	NSNumber * minLat;
	NSNumber * spanLon;
	NSNumber * maxLon;
	NSNumber * district;
	id lineColor;
	NSNumber * minLon;
	NSNumber * centerLat;
	NSNumber *pinColorIndex;
	NSString *updated;
	NSString *coordinatesBase64;
	LegislatorObj *legislator;
}

@property (nonatomic, retain) NSNumber * districtMapID;
@property (nonatomic, retain) NSNumber * chamber;
@property (nonatomic, retain) NSNumber * centerLon;
@property (nonatomic, retain) NSNumber * spanLat;
@property (nonatomic, retain) NSNumber * lineWidth;
@property (nonatomic, retain) NSData * coordinatesData;
@property (nonatomic, retain) NSString * coordinatesBase64;
@property (nonatomic, retain) NSNumber * numberOfCoords;
@property (nonatomic, retain) NSNumber * maxLat;
@property (nonatomic, retain) NSNumber * minLat;
@property (nonatomic, retain) NSNumber * spanLon;
@property (nonatomic, retain) NSNumber * maxLon;
@property (nonatomic, retain) NSNumber * district;
@property (nonatomic, retain) id lineColor;
@property (nonatomic, retain) NSNumber * minLon;
@property (nonatomic, retain) NSNumber * centerLat;
@property (nonatomic, retain) NSNumber * pinColorIndex;
@property (nonatomic, retain) NSString * updated;
@property (nonatomic, retain) LegislatorObj * legislator;

@property (nonatomic, readonly) CLLocationCoordinate2D	coordinate;
@property (nonatomic, readonly) MKCoordinateRegion		region;
@property (nonatomic, readonly) MKCoordinateSpan		span;

- (void)resetRelationship:(id)sender;
- (UIImage *)image;
- (MKPolyline *)polyline;
- (MKPolygon *)polygon;

- (BOOL) districtContainsCoordinate:(CLLocationCoordinate2D)aCoordinate;

- (id) initWithCoder: (NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;	
+ (NSArray *)lightPropertiesToFetch;

@end



