//
//  TexLegeNavBar.m
//  TexLege
//
//  Created by Gregory Combs on 2/5/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//
//	Fixes a retarded bug in iOS 4.2.x that incorrectly deletes and ignores tintColor after opening in a popover/splitview

#import "TexLegeNavBar.h"
#import "TexLegeTheme.h"

@implementation TexLegeNavBar

- (void)setTintColor:(UIColor *)tintColor
{
	// Bug workaround. 
	
	[super setTintColor:[self tintColor]];
}

@end
