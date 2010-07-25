//
//  PartisanIndexStats.m
//  TexLege
//
//  Created by Gregory Combs on 7/9/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "PartisanIndexStats.h"
#import "LegislatorObj.h"

@interface PartisanIndexStats (Private)

- (NSArray *) aggregatePartisanIndexForChamber:(NSInteger)chamber andPartyID:(NSInteger)party;
- (NSArray *) allMembersByChamber:(NSInteger)chamber andPartyID:(NSInteger)party;



@end

@implementation PartisanIndexStats

@synthesize managedObjectContext;

SYNTHESIZE_SINGLETON_FOR_CLASS(PartisanIndexStats);

// setup the data collection
- init {
	if (self = [super init]) {

	}
	return self;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)newContext {
	if ([self init]) {
		self.managedObjectContext = newContext;
		m_partisanIndexAggregates = nil;
		
		// initialize these
		[self partisanIndexAggregates];
	
	}
	return self;
}

- (void)dealloc {	
	self.managedObjectContext = nil;
	if (m_partisanIndexAggregates) [m_partisanIndexAggregates release], m_partisanIndexAggregates = nil;
	
    [super dealloc];
}

- (NSNumber *) currentSessionYear {
	return [NSNumber numberWithInteger:2009];
}

- (NSDictionary *)partisanIndexAggregates {
	
	if (m_partisanIndexAggregates == nil) {
		
		NSMutableDictionary *tempAggregates = [NSMutableDictionary dictionaryWithCapacity:4];
		NSInteger chamber, party;
		for (chamber = HOUSE; chamber <= SENATE; chamber++) {
			for (party = kUnknownParty; party <= REPUBLICAN; party++) {
				NSArray *aggregatesArray = [self aggregatePartisanIndexForChamber:chamber andPartyID:party];
				NSNumber *avgIndex = [aggregatesArray objectAtIndex:0];
				if (avgIndex)
					[tempAggregates setObject:avgIndex forKey:[NSString stringWithFormat:@"AvgC%d+P%d", chamber, party]];
				
				NSNumber *maxIndex = [aggregatesArray objectAtIndex:1];
				if (maxIndex)
					[tempAggregates setObject:maxIndex forKey:[NSString stringWithFormat:@"MaxC%d+P%d", chamber, party]];
				
				NSNumber *minIndex = [aggregatesArray objectAtIndex:2];
				if (minIndex)
					[tempAggregates setObject:minIndex forKey:[NSString stringWithFormat:@"MinC%d+P%d", chamber, party]];
				
			}
		}
		//NSLog(@"Index Aggregates: %@", [tempAggregates description]);			
		m_partisanIndexAggregates = [[NSDictionary dictionaryWithDictionary:tempAggregates] retain];
	}

	return m_partisanIndexAggregates;
}

- (NSNumber *) minPartisanIndexUsingLegislator:(LegislatorObj *)legislator {
	return [self.partisanIndexAggregates objectForKey:
			[NSString stringWithFormat:@"MinC%d+P0", [legislator.legtype integerValue]]];
};

- (NSNumber *) maxPartisanIndexUsingLegislator:(LegislatorObj *)legislator {
	return [self.partisanIndexAggregates objectForKey:
			[NSString stringWithFormat:@"MaxC%d+P0", [legislator.legtype integerValue]]];
};

- (NSNumber *) overallPartisanIndexUsingLegislator:(LegislatorObj *)legislator {
	return [self.partisanIndexAggregates objectForKey:
			[NSString stringWithFormat:@"AvgC%d+P0", [legislator.legtype integerValue]]];
};


- (NSNumber *) partyPartisanIndexUsingLegislator:(LegislatorObj *)legislator {
	return [self.partisanIndexAggregates objectForKey:
			[NSString stringWithFormat:@"AvgC%d+P%d", [legislator.legtype integerValue], [legislator.party_id integerValue]]];
};


#pragma mark -
#pragma mark Partisan Indexing

- (NSArray *) aggregatePartisanIndexForChamber:(NSInteger)chamber andPartyID:(NSInteger)party {
	
	if (chamber == BOTH_CHAMBERS) {
		NSLog(@"allMembersByChamber: ... cannot be BOTH chambers");
		return nil;
	}
	
	NSString *predicateString = nil;
	if (party > kUnknownParty)
		predicateString = [NSString stringWithFormat:@"legtype == %d AND party_id == %d", chamber, party];
	else
		predicateString = [NSString stringWithFormat:@"legtype == %d", chamber];	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString]; 
	/*_____________________*/
	
	NSExpression *ex = [NSExpression expressionForFunction:@"average:" arguments:
						[NSArray arrayWithObject:[NSExpression expressionForKeyPath:@"partisan_index"]]];
	NSExpressionDescription *edAvg = [[NSExpressionDescription alloc] init];
	[edAvg setName:@"averagePartisanIndex"];
	[edAvg setExpression:ex];
	[edAvg setExpressionResultType:NSFloatAttributeType];
	
	ex = [NSExpression expressionForFunction:@"max:" arguments:
						[NSArray arrayWithObject:[NSExpression expressionForKeyPath:@"partisan_index"]]];
	NSExpressionDescription *edMax = [[NSExpressionDescription alloc] init];
	[edMax setName:@"maxPartisanIndex"];
	[edMax setExpression:ex];
	[edMax setExpressionResultType:NSFloatAttributeType];
	
	ex = [NSExpression expressionForFunction:@"min:" arguments:
		  [NSArray arrayWithObject:[NSExpression expressionForKeyPath:@"partisan_index"]]];
	NSExpressionDescription *edMin = [[NSExpressionDescription alloc] init];
	[edMin setName:@"minPartisanIndex"];
	[edMin setExpression:ex];
	[edMin setExpressionResultType:NSFloatAttributeType];
	
	/*_____________________*/

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setPredicate:predicate];
	[request setPropertiesToFetch:[NSArray arrayWithObjects:edAvg, edMax, edMin, nil]];
	[request setResultType:NSDictionaryResultType];
	[edAvg release], [edMax release], [edMin release];
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LegislatorObj" 
											  inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSError *error;
	NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
	if (objects == nil) {
		// Handle the error.
		NSLog(@"Error");
	}
	else {
		if ([objects count] > 0) {
			NSNumber *avgPartisanIndex = [[objects objectAtIndex:0] valueForKey:@"averagePartisanIndex"];
			NSNumber *maxPartisanIndex = [[objects objectAtIndex:0] valueForKey:@"maxPartisanIndex"];
			NSNumber *minPartisanIndex = [[objects objectAtIndex:0] valueForKey:@"minPartisanIndex"];
			//return [avgPartisanIndex floatValue];
			return [NSArray arrayWithObjects:avgPartisanIndex, maxPartisanIndex, minPartisanIndex, nil];
		}
	}
	
	return nil;
	
}

- (NSString *) partisanRankForLegislator:(LegislatorObj *)legislator onlyParty:(BOOL)inParty {
	
	NSArray *legislators = nil;
	
	if (inParty)
		legislators = [self allMembersByChamber:[legislator.legtype integerValue] 
									 andPartyID:[legislator.party_id integerValue]];
	else
		legislators = [self allMembersByChamber:[legislator.legtype integerValue] 
									 andPartyID:kUnknownParty];
	
	if (legislators) {
		NSInteger rank = [legislators indexOfObject:legislator] + 1;
		NSInteger count = [legislators count];
		return [NSString stringWithFormat:@"%d out of %d", rank, count];	
	}
	else {
		return nil;
	}
}


- (NSArray *) allMembersByChamber:(NSInteger)chamber andPartyID:(NSInteger)party
{
	if (chamber == BOTH_CHAMBERS) {
		NSLog(@"allMembersByChamber: ... cannot be BOTH chambers");
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"LegislatorObj" 
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	NSString *predicateString = nil;
	if (party > kUnknownParty)
		predicateString = [NSString stringWithFormat:@"legtype == %d AND party_id == %d", chamber, party];
	else
		predicateString = [NSString stringWithFormat:@"legtype == %d", chamber];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString]; 
	[fetchRequest setPredicate:predicate];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"partisan_index" ascending:(party != REPUBLICAN)];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	
	NSError *error;
	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	[fetchRequest release];
	//if (error)
	//	NSLog(@"allMembersByChamber:andParty: error in executeFetchRequest: %@, %@", error, [error userInfo]);
	
	return fetchedObjects;
	
}

- (NSDictionary *) historyForParty:(NSInteger)party Chamber:(NSInteger)chamber {
	NSDictionary *historyDict = nil;
		
	if (party == REPUBLICAN && chamber == HOUSE)
		historyDict = [NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.54409], [NSNumber numberWithInteger:72],
					   [NSNumber numberWithFloat:0.559875531], [NSNumber numberWithInteger:73],
					   [NSNumber numberWithFloat:0.552640372], [NSNumber numberWithInteger:74],
					   [NSNumber numberWithFloat:0.621388023], [NSNumber numberWithInteger:75],
					   [NSNumber numberWithFloat:0.629700791], [NSNumber numberWithInteger:76],
					   [NSNumber numberWithFloat:0.621778609], [NSNumber numberWithInteger:77],
					   [NSNumber numberWithFloat:0.621042716], [NSNumber numberWithInteger:78],
					   [NSNumber numberWithFloat:0.617089494], [NSNumber numberWithInteger:79],
					   [NSNumber numberWithFloat:0.636998902], [NSNumber numberWithInteger:80],
					   [NSNumber numberWithFloat:0.734943024], [NSNumber numberWithInteger:81],nil];
	else if (party == DEMOCRAT && chamber == HOUSE)
		historyDict = [NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:-0.42222], [NSNumber numberWithInteger:72],
					   [NSNumber numberWithFloat:-0.449964135], [NSNumber numberWithInteger:73],
					   [NSNumber numberWithFloat:-0.445684078], [NSNumber numberWithInteger:74],
					   [NSNumber numberWithFloat:-0.536115388], [NSNumber numberWithInteger:75],
					   [NSNumber numberWithFloat:-0.581599285], [NSNumber numberWithInteger:76],
					   [NSNumber numberWithFloat:-0.585928296], [NSNumber numberWithInteger:77],
					   [NSNumber numberWithFloat:-0.644611479], [NSNumber numberWithInteger:78],
					   [NSNumber numberWithFloat:-0.695038928], [NSNumber numberWithInteger:79],
					   [NSNumber numberWithFloat:-0.689908867], [NSNumber numberWithInteger:80],
					   [NSNumber numberWithFloat:-0.816011438], [NSNumber numberWithInteger:81],nil];
	else if (party == REPUBLICAN && chamber == SENATE)
		historyDict = [NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:0.4383], [NSNumber numberWithInteger:76],
					   [NSNumber numberWithFloat:0.607931], [NSNumber numberWithInteger:77],
					   [NSNumber numberWithFloat:0.799931], [NSNumber numberWithInteger:78],
					   [NSNumber numberWithFloat:0.722995], [NSNumber numberWithInteger:79],
					   [NSNumber numberWithFloat:0.386157], [NSNumber numberWithInteger:80],
					   [NSNumber numberWithFloat:0.599742], [NSNumber numberWithInteger:81],nil];
	else if (party == DEMOCRAT && chamber == SENATE)
		historyDict = [NSDictionary dictionaryWithObjectsAndKeys:
					   [NSNumber numberWithFloat:-0.4161], [NSNumber numberWithInteger:76],
					   [NSNumber numberWithFloat:-0.5796], [NSNumber numberWithInteger:77],
					   [NSNumber numberWithFloat:-0.833222], [NSNumber numberWithInteger:78],
					   [NSNumber numberWithFloat:-0.656078], [NSNumber numberWithInteger:79],
					   [NSNumber numberWithFloat:-0.688802], [NSNumber numberWithInteger:80],
					   [NSNumber numberWithFloat:-0.69183], [NSNumber numberWithInteger:81],nil];
	
	return historyDict;
}

@end
