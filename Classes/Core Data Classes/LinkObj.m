// 
//  LinkObj.m
//  TexLege
//
//  Created by Gregory Combs on 7/10/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//

#import "LinkObj.h"


@implementation LinkObj

@dynamic order;
@dynamic url;
@dynamic label;
//@dynamic timeStamp;
@dynamic section;

- (void) importFromDictionary: (NSDictionary *)dictionary
{				
	if (dictionary)
		[self setValuesForKeysWithDictionary:dictionary];
}


- (NSDictionary *)exportToDictionary {
	NSArray *keys = [NSArray arrayWithObjects:
					 @"order",
					 @"url",
					 @"label",
					 @"section",
//					 @"timeStamp",			// we don't use this, so it's NULL anyway
					 nil];
	
	NSDictionary *tempDict = [self dictionaryWithValuesForKeys:keys];
	return tempDict;
}


@end
