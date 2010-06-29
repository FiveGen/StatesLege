// 
//  CommitteeObj.m
//  TexLege
//
//  Created by Gregory Combs on 7/11/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//

#import "CommitteeObj.h"

#import "CommitteePositionObj.h"
#import "LegislatorObj.h"

@implementation CommitteeObj 

@dynamic clerk;
@dynamic clerk_email;
@dynamic phone;
@dynamic office;
@dynamic parentId;
@dynamic committeeId;
@dynamic url;
@dynamic committeeName;
@dynamic committeeType;
@dynamic committeeNameInitial;
@dynamic committeePositions;

- (NSString *) committeeNameInitial {
	[self willAccessValueForKey:@"committeeNameInitial"];
	NSString * initial = [[self committeeName] substringToIndex:1];
	[self didAccessValueForKey:@"committeeNameInitial"];
	return initial;
}

- (NSString*)typeString {
	NSString * tempString = ([[self committeeType] integerValue] == HOUSE) ? @"House" : @"Senate";
	return tempString;
}

- (NSString*)description {
	NSString  *typeName = [NSString stringWithFormat: @"%@ (%@)", [self committeeName], [self typeString]];
	return typeName;
}

- (LegislatorObj *)chair
{
	for (CommitteePositionObj *position in [self committeePositions]) {
		if ([[position position] integerValue] == POS_CHAIR)
			return position.legislator;
	}
	 return nil;
}
				 
- (LegislatorObj *)vicechair
{
	for (CommitteePositionObj *position in [self committeePositions]) {
		if ([[position position] integerValue] == POS_VICE)
			return position.legislator;
	}
	return nil;
}

- (NSArray *)sortedMembers
{
	//return [[self.committeePositions allObjects] 
	//		sortedArrayUsingSelector:@selector(compareMembersByName:)];

	NSMutableArray *memberArray = [[[NSMutableArray alloc] init] autorelease];
	for (CommitteePositionObj *position in [self committeePositions]) {
		if ([[position position] integerValue] == POS_MEMBER)
			[memberArray addObject:position.legislator];
	}
	[memberArray sortUsingSelector:@selector(compareMembersByName:)];

	return memberArray;
}

@end
