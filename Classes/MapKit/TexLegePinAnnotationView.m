//
//  TexLegePinAnnotationView.m
//  TexLege
//
//  Created by Gregory Combs on 9/13/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "TexLegePinAnnotationView.h"
#import "DistrictMapObj.h"
#import "DistrictOfficeObj.h"
#import "TexLegeMapPins.h"

@interface TexLegePinAnnotationView (Private)
- (void)resetPinColorWithAnnotation:(id <MKAnnotation>)anAnnotation;
@end
	
@implementation TexLegePinAnnotationView


- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])) {
		self.animatesDrop = YES;
		self.opaque = NO;
		self.draggable = NO;
		self.canShowCallout = YES;
		
		[self resetPinColorWithAnnotation:annotation];
		
	}
	return self;
}

- (void)resetPinColorWithAnnotation:(id <MKAnnotation>)anAnnotation {
	if (!anAnnotation || 
		(![anAnnotation isKindOfClass:[DistrictMapObj class]] && ![anAnnotation isKindOfClass:[DistrictOfficeObj class]]))  
		return;
		
	UIView *foundPinImage = nil;
	for (UIView* suspect in self.subviews) {
		if (suspect.tag == 999) {
			foundPinImage = suspect;
			continue;
		}
	}
	
	if (foundPinImage)
		[foundPinImage removeFromSuperview];
	
	NSInteger pinColorIndex = MKPinAnnotationColorRed;
	
	NSNumber *pinColorNumber = [anAnnotation performSelector:@selector(pinColorIndex)];
	if (!pinColorNumber)
		self.pinColor = pinColorIndex;
	else if ([pinColorNumber integerValue] < TexLegePinAnnotationColorBlue)
		self.pinColor = [pinColorNumber integerValue];
	else {
		NSInteger pinColorIndex = [pinColorNumber integerValue];
		
		UIImage *pinImage = [TexLegeMapPins imageForPinColorIndex:pinColorIndex status:TexLegePinAnnotationStatusHead];
		UIImageView *pinHead = [[UIImageView alloc] initWithImage:pinImage];
		pinHead.tag = 999;
		[self addSubview:pinHead];
		[pinHead release];
	}
	
	UIImage *anImage = [self.annotation performSelector:@selector(image)];
	if (anImage) {
		UIImageView *iconView = [[UIImageView alloc] initWithImage:anImage];
		self.leftCalloutAccessoryView = iconView;
		[iconView release];
	}
}

- (void)setAnnotation:(id <MKAnnotation>)newAnnotation {
	[super setAnnotation:newAnnotation];
	
	[self resetPinColorWithAnnotation:newAnnotation];
}

@end
