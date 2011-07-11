//
//  MultiPolyline.m
//  Created by Gregory Combs on 8/25/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//
//	James Howard at Apple came up with this on the Developer Forums
//	https://devforums.apple.com/thread/48154?tstart=0


#import "MultiPolyline.h"


@implementation MultiPolyline

@synthesize polylines = _polylines;

- (id)initWithPolylines:(NSArray *)polylines
{
    if (self = [super init]) {
        _polylines = [polylines copy];
		
        NSUInteger polyCount = [_polylines count];
        if (polyCount) {
            _boundingMapRect = [[_polylines objectAtIndex:0] boundingMapRect];
            NSUInteger i;
            for (i = 1; i < polyCount; i++) {
                _boundingMapRect = MKMapRectUnion(_boundingMapRect, [[_polylines objectAtIndex:i] boundingMapRect]);
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [_polylines release];
    [super dealloc];
}

- (MKMapRect)boundingMapRect
{
    return _boundingMapRect;
}

- (CLLocationCoordinate2D)coordinate
{
    return MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(_boundingMapRect), MKMapRectGetMidY(_boundingMapRect)));
}

@end