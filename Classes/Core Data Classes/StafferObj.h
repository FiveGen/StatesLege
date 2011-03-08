//
//  StafferObj.h
//  TexLege
//
//  Created by Gregory Combs on 1/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

@class LegislatorObj;

@interface StafferObj :  RKManagedObject
{
	NSNumber * stafferID;
	NSNumber * legislatorID;
	NSString * name;
	NSString * title;
	NSString * phone;
	NSString * email;
	NSString * updated;	
	LegislatorObj * legislator;
}

@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSNumber * legislatorID;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * stafferID;
@property (nonatomic, retain) LegislatorObj * legislator;
@property (nonatomic, retain) NSString * updated;

@end



