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
#import "TexLegeCoreDataUtils.h"

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

@dynamic votesmartID;
@dynamic openstatesID;
@dynamic txlonline_id;

- (void) importFromDictionary: (NSDictionary *)dictionary
{				
	if (dictionary) {
		self.clerk = [dictionary objectForKey:@"clerk"];
		self.clerk_email = [dictionary objectForKey:@"clerk_email"];
		self.phone = [dictionary objectForKey:@"phone"];
		self.parentId = [dictionary objectForKey:@"parentId"];
		self.committeeId = [dictionary objectForKey:@"committeeId"];
		self.url = [dictionary objectForKey:@"url"];
		self.office = [dictionary objectForKey:@"office"];
		self.committeeName = [dictionary objectForKey:@"committeeName"];
		self.committeeType = [dictionary objectForKey:@"committeeType"];

		self.votesmartID = [dictionary objectForKey:@"votesmartID"];
		self.openstatesID = [dictionary objectForKey:@"openstatesID"];
		self.txlonline_id = [dictionary objectForKey:@"txlonline_id"];

	}
}


- (NSDictionary *)exportToDictionary {
	
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	[tempDict setObject:self.clerk forKey:@"clerk"];
	[tempDict setObject:self.clerk_email forKey:@"clerk_email"];
	[tempDict setObject:self.office forKey:@"office"];
	[tempDict setObject:self.phone forKey:@"phone"];
	[tempDict setObject:self.parentId forKey:@"parentId"];
	[tempDict setObject:self.committeeId forKey:@"committeeId"];
	[tempDict setObject:self.url forKey:@"url"];
	[tempDict setObject:self.committeeName forKey:@"committeeName"];
	[tempDict setObject:self.committeeType forKey:@"committeeType"];
	
	[tempDict setObject:self.votesmartID forKey:@"votesmartID"];
	[tempDict setObject:self.openstatesID forKey:@"openstatesID"];
	[tempDict setObject:self.txlonline_id forKey:@"txlonline_id"];

	return tempDict;
}

- (id)proxyForJson {
    return [self exportToDictionary];
}


- (NSString *) committeeNameInitial {
	[self willAccessValueForKey:@"committeeNameInitial"];
	NSString * initial = [[self committeeName] substringToIndex:1];
	[self didAccessValueForKey:@"committeeNameInitial"];
	return initial;
}

- (NSString*)typeString {
	switch ([self.committeeType integerValue]) {
		case JOINT:
			return @"Joint";
			break;
		case HOUSE:
			return @"House";
			break;
		case SENATE:
			return @"Senate";
			break;
		default:
			return @"All";
			break;
	}
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
