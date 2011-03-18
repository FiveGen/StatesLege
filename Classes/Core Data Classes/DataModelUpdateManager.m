//
//  DataModelUpdateManager.m
//  TexLege
//
//  Created by Gregory Combs on 1/26/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//

#import "DataModelUpdateManager.h"
#import "JSON.h"
#import "UtilityMethods.h"
#import "TexLegeReachability.h"
#import "TexLegeCoreDataUtils.h"
#import "MTStatusBarOverlay.h"
#import "LocalyticsSession.h"
#import "DistrictMapObj.h"
#import "NSDate+Helper.h"

#define JSONDATA_IDKEY			@"id"
#define JSONDATA_ENCODING		NSUTF8StringEncoding

#define TXLUPDMGR_CLASSKEY		@"className"
#define TXLUPDMGR_QUERYKEY		@"queryType"
#define TXLUPDMGR_UPDATEDPROP	@"updated"
#define TXLUPDMGR_UPDATEDPARAM	@"updated_since"

						// QUERIES RETURN AN ARRAY OF ROWS
enum TXL_QueryTypes {
	QUERYTYPE_IDS_NEW = 1,		//	 *filtered* by updated_since;	contains only primaryKey
	QUERYTYPE_IDS_ALL_PRUNE,	//	 **PRUNES CORE DATA**		;	contains only primaryKey
	QUERYTYPE_COMPLETE_NEW,		//   *filtered* by updated_since;	contains *all* properties
	QUERYTYPE_COMPLETE_ALL		//						all rows;	contains *all* properties
};
#define queryIsComplete(query) (query >= QUERYTYPE_COMPLETE_NEW)
#define queryIsNew(query) ((query == QUERYTYPE_IDS_NEW) || (query == QUERYTYPE_COMPLETE_NEW))

#define numToInt(number) (number ? [number integerValue] : 0)	// should this be NSNotFound or nil or null?
#define intToNum(integer) [NSNumber numberWithInt:integer]

#define TESTING 0	// turn this on to fake the updater into believing all remote data is newer than local.  
#define WNOMAGGREGATES_UPDATING 0

@interface DataModelUpdateManager (Private)

- (void) performDataUpdateIfAvailableForModel:(NSString *)entityName;
- (NSString *)localDataTimestampForModel:(NSString *)classString;

#if WNOMAGGREGATES_UPDATING
/*
- (NSArray *) localDataTimestamps;
- (NSArray *) remoteDataTimestamps;
- (NSArray *) deltaLocalTimestamps:(NSArray *)local toRemote:(NSArray *)remote;
*/
- (NSString *) localDataTimestampForArray:(NSArray *)entityArray;
#endif	

@end

@implementation DataModelUpdateManager

@synthesize statusBlurbsAndModels;
@synthesize availableUpdates, activeUpdates;

- (id) init {
	if (self=[super init]) {
		activeUpdates = [[[NSCountedSet alloc] init] retain];
		
		availableUpdates = [[NSMutableDictionary dictionary] retain];
		
		self.statusBlurbsAndModels = [NSDictionary dictionaryWithObjectsAndKeys: 
									  @"Legislators", @"LegislatorObj",
									  @"Partisanship Scores", @"WnomObj",
									  @"Staffers", @"StafferObj",
									  @"Committees", @"CommitteeObj",
									  @"Committee Positions", @"CommitteePositionObj",
									  @"District Offices", @"DistrictOfficeObj",
									  @"Resources", @"LinkObj",
									  @"District Maps", @"DistrictMapObj",
									  @"Party Scores", @"WnomAggregateObj",
									  nil];		

	}
	return self;
}

- (void) dealloc {
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];

	self.activeUpdates = nil;
	self.statusBlurbsAndModels = nil;
	self.availableUpdates = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Check & Perform Updates

- (void) performDataUpdatesIfAvailable:(id)sender {
	NSArray *objects = [self.statusBlurbsAndModels allKeys];
	//NSArray *objects = [TexLegeCoreDataUtils registeredDataModels];

	NSURL *serverURL = [NSURL URLWithString:RESTKIT_BASE_URL];
	
	if ([TexLegeReachability canReachHostWithURL:serverURL alert:NO]) {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"DATABASE_UPDATE_REQUEST"];

		self.activeUpdates = [NSCountedSet set];
				
		NSString *statusString = @"Checking for Data Updates";
		MTStatusBarOverlay *overlay = [MTStatusBarOverlay sharedInstance];
		overlay.historyEnabled = YES;
		overlay.animation = MTStatusBarOverlayAnimationFallDown;  // MTStatusBarOverlayAnimationShrink
		overlay.detailViewMode = MTDetailViewModeHistory;         // enable automatic history-tracking and show in detail-view
		//overlay.delegate = self;
		overlay.progress = 0.0;
		[overlay postMessage:statusString animated:YES];

		
		for (NSString *classString in objects) {
			[self performDataUpdateIfAvailableForModel:classString];
		}		
	}
}

// Send a simple query to our server's REST API.  The queryType determines the content and the resulting actions once we receive the response

- (void) queryModel:(NSString *)entityName queryType:(NSInteger)queryType {
	NSMutableString *resourcePath = [[NSMutableString alloc] init];
	NSDictionary *queryParams = nil;
	
	if (queryIsComplete(queryType)) 
		[resourcePath appendFormat:@"/rest.php/%@", entityName];
	else
		[resourcePath appendFormat:@"/rest_ids.php/%@", entityName];
		
	if (queryIsNew(queryType)) {
		NSString *localTS = [self localDataTimestampForModel:entityName];
		queryParams = [NSDictionary dictionaryWithObjectsAndKeys:localTS,TXLUPDMGR_UPDATEDPARAM,nil];
	}
	
	RKRequest *request = nil;
	if (queryParams)
		request = [[RKClient sharedClient] get:resourcePath queryParams:queryParams delegate:self];
	else
		request = [[RKClient sharedClient] get:resourcePath delegate:self];

	if (request) {
		NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
								  entityName, TXLUPDMGR_CLASSKEY,
								  intToNum(queryType), TXLUPDMGR_QUERYKEY, nil];
		
		request.userData = userData;
	}
	else
		NSLog(@"DataUpdateManager Error, unable to obtain RestKit request for %@", resourcePath);
	
	[resourcePath release];
}

- (void) performDataUpdateIfAvailableForModel:(NSString *)entityName {	
	NSString *localTS = [self localDataTimestampForModel:entityName];
	
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	NSString *resourcePath = [NSString stringWithFormat:@"/rest.php/%@", entityName];
	NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:localTS,TXLUPDMGR_UPDATEDPARAM,nil];
	//	http://www.texlege.com/jsonDataTest/rest.php/CommitteeObj?updated_since=2011-03-01%2017:05:13
	
	Class entityClass = NSClassFromString(entityName);
	if (entityClass) {							
		[self.activeUpdates addObject:entityName];		// we don't add WnomAggregateObj because we don't get it loaded the same way.
		
		[objectManager loadObjectsAtResourcePath:resourcePath queryParams:queryParams objectClass:entityClass delegate:self];
	}
	else if ([entityName isEqualToString:@"WnomAggregateObj"]) {
#if WNOMAGGREGATES_UPDATING
		//TODO:	Figure out some way of pulling the latest and greatest WnomAggregateObj once in a while.
		//		This requires WnomAggregateObj.json to be copied and updated in the documents directory (right now it's only in the bundle)
	#warning This requires WnomAggregateObj to be in the documents directory (it's only in the app bundle now)
#endif
	}
	else {
		debug_NSLog(@"DataUpdateManager:performDataUpdateIfAvailableForModel - Unexpected entity name: %@", entityName);
	}
}

- (void)updateProgress {
	//BOOL success = self.availableUpdates && ([self.downloadedUpdates count] == [self.availableUpdates count]);
	//CGFloat progress = (CGFloat)([self.downloadedUpdates count]) / (CGFloat)[self.availableUpdates count];
	
	NSInteger count = [self.activeUpdates count];
	CGFloat progress = 1.0f;
	if (count > 0)
		progress = 1.0f / (CGFloat)count;
	
	[MTStatusBarOverlay sharedInstance].progress = progress;

	if (count == 0)
		[[MTStatusBarOverlay sharedInstance] postFinishMessage:@"Update Completed" duration:5];	
}


// This scans the core data entity looking for "stale" objects, ones that were deleted on the server database
- (void)pruneModel:(NSString *)className forUpstreamIDs:(NSArray *)upstreamIDs {
	Class entityClass = NSClassFromString(className);

	if (!entityClass || ![[TexLegeCoreDataUtils registeredDataModels] containsObject:className])
		return;			// What do we do for WnomAggregateObj ???

	RKObjectManager* objectManager = [RKObjectManager sharedManager];

	BOOL changed = NO;
	
	NSSet *existingSet = [NSSet setWithArray:[TexLegeCoreDataUtils allPrimaryKeyIDsInEntityNamed:className]];	
	NSSet *newSet = [NSSet setWithArray:upstreamIDs];
	
	// Determine which items were removed
	NSMutableSet *removedItems = [NSMutableSet setWithSet:existingSet];
	[removedItems minusSet:newSet];
	
	// Determine which items were added
	NSMutableSet *addedItems = [NSMutableSet setWithSet:newSet];
	[addedItems minusSet:existingSet];
	
	// Modify the original array
	//[existingItemArray removeObjectsInArray:[removedItems allObjects]];
	//[existingItemArray addObjectsFromArray:[addedItems allObjects]];
	
	// TESTING PURPOSES
	/*#warning TESTING PURPOSES
	if ([className isEqualToString:@"LegislatorObj"]) {
		[addedItems removeObject:intToNum(116944)];		// delete jose aliseda
		[removedItems addObject:intToNum(116944)];		// delete jose aliseda
	}
	else {
		// We'd actually need to remove his staffers, district offices, wnom, etc.
		// and make sure we remove them from the list of people to be added too.
	}*/



	
	
	for (NSNumber *staleObjID in removedItems) {
		NSLog(@"DataUpdateManager: PRUNING OBJECT FROM %@: ID = %@", className, staleObjID);
		[TexLegeCoreDataUtils deleteObjectInEntityNamed:className withPrimaryKeyValue:staleObjID];			
		changed = YES;
	}
	if (changed) {
		[[objectManager objectStore] save];
		
		NSString *notification = [NSString stringWithFormat:@"RESTKIT_LOADED_%@", [className uppercaseString]];
		[[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
		
		NSString *statusString = [NSString stringWithFormat:@"Pruned %@", [statusBlurbsAndModels objectForKey:className]];
		[[MTStatusBarOverlay sharedInstance] postImmediateMessage:statusString duration:1 animated:YES];
	}	
		
	// Now we need to add any *completely* new (not just updated) objects on the server, and download accordingly
	for (NSNumber *newObjID in addedItems) {
		[self.activeUpdates addObject:className];
		NSString *resourcePath = [NSString stringWithFormat:@"/rest.php/%@/%@", className, newObjID];
		[objectManager loadObjectsAtResourcePath:resourcePath objectClass:entityClass delegate:self];
	}
	
	
}

#pragma mark -
#pragma mark RKRequestDelegate methods

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if (error && request) {
		debug_NSLog(@"Error loading data model query from %@: %@", [request description], [error localizedDescription]);		
	}	
}


// Handling GET Requests  
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data  
		
		if (!request.userData)
			return; // We've got no user data, can't do anything...

		NSString *className = [request.userData objectForKey:TXLUPDMGR_CLASSKEY];
		NSInteger queryType = numToInt([request.userData objectForKey:TXLUPDMGR_QUERYKEY]);
		
		if (NO == queryIsComplete(queryType)) { // we're only working with an array of IDs
			NSArray *resultIDs = [response bodyAsJSON];
			if (resultIDs && [resultIDs count]) {
				if (queryType == QUERYTYPE_IDS_NEW)
					[self.availableUpdates setObject:resultIDs forKey:className];
				else if (queryType == QUERYTYPE_IDS_ALL_PRUNE)
					[self pruneModel:className forUpstreamIDs:resultIDs];
			}
		}
	}
}		

#pragma mark -
#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	NSString *className = NSStringFromClass(objectLoader.objectClass);

	@try {
		if (className) {
			[self.activeUpdates removeObject:className];

			if (objects && [objects count]) {
				NSString *notification = [NSString stringWithFormat:@"RESTKIT_LOADED_%@", [className uppercaseString]];
				debug_NSLog(@"%@ %d objects", notification, [objects count]);
			
				if ([className isEqualToString:@"DistrictMapObj"] || [className isEqualToString:@"LegislatorObj"])					
					for (DistrictMapObj *map in [DistrictMapObj allObjects])
						[map resetRelationship:self];
			
				[[[RKObjectManager sharedManager] objectStore] save];
				[[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
				
				NSString *statusString = [NSString stringWithFormat:@"Updated %@", [statusBlurbsAndModels objectForKey:className]];
				NSLog(@"%@", statusString);
				[[MTStatusBarOverlay sharedInstance] postMessage:statusString animated:YES];				

			}
			[self queryModel:className queryType:QUERYTYPE_IDS_ALL_PRUNE];	// THIS TRIGGERS A PRUNING
			
			[self updateProgress];
		}			
	}
	@catch (NSException * e) {
		NSLog(@"RestKit Load Error %@: %@", className, [e description]);
	}
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	//if ([error code] != NSValidationMissingMandatoryPropertyError)
	/*	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Data Update Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];*/
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"RESTKIT_DATA_ERROR"];
	[[MTStatusBarOverlay sharedInstance] postErrorMessage:@"Error During Update" duration:8];

	NSString *className = NSStringFromClass(objectLoader.objectClass);
	if (className)
		[self.activeUpdates removeObject:className];
	
	NSLog(@"RestKit Data error loading %@: %@", className, [error localizedDescription]);
}

#pragma mark -
#pragma mark Timestamp Files

- (NSString *)localDataTimestampForModel:(NSString *)classString {
	if (NSClassFromString(classString)) {
		NSFetchRequest *request = [NSClassFromString(classString) fetchRequest];
		NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:TXLUPDMGR_UPDATEDPROP ascending:NO];	// the most recent update will be the first item in the array (descending)
		[request setSortDescriptors:[NSArray arrayWithObject:desc]];
		[request setResultType:NSDictionaryResultType];												// This is necessary to limit it to specific properties during the fetch
		[request setPropertiesToFetch:[NSArray arrayWithObject:TXLUPDMGR_UPDATEDPROP]];						// We don't want to fetch everything, we'll get a huge ass memory hit otherwise.
		[desc release];
		
		return [[NSClassFromString(classString) objectWithFetchRequest:request] valueForKey:TXLUPDMGR_UPDATEDPROP];	// this relies on objectWithFetchRequest returning the object at index 0
	}
	else if ([classString isEqualToString:@"WnomAggregateObj"]) {
#if WNOMAGGREGATES_UPDATING
		NSError *error = nil;
		NSString *path = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:@"WnomAggregateObj.json"];
		NSString *json = [NSString stringWithContentsOfFile:path encoding:JSONDATA_ENCODING error:&error];
		if (!error && json) {
			NSArray *aggregates = [json JSONValue];
			NSString *timestamp = [self localDataTimestampForArray:aggregates];
		}
		else {
			NSLog(@"DataModelUpdateManager:timestampForModel - error loading aggregates json - %@", path);
		}
#endif
	}
	
	return nil;
}

#if WNOMAGGREGATES_UPDATING
- (NSString *) localDataTimestampForArray:(NSArray *)entityArray {
	if (!entityArray || ![entityArray count])
		return [[NSDate date] timestampString];
	
	NSMutableArray *tempSorted = [[NSMutableArray alloc] initWithArray:entityArray];
	NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:JSONDATA_TIMESTAMPKEY ascending:NO];	// the most recent update will be the first item in the array (descending)
	[tempSorted sortUsingDescriptors:desc];
	[desc release];

	NSString *timestamp = nil;
	id object = [[tempSorted objectAtIndex:0] objectForKey:JSONDATA_TIMESTAMPKEY];
	if (!object) {
		NSLog(@"DataModelUpdateManager:timestampForArray - no 'updated' timestamp key found.");
	}
	else if ([object isKindOfClass:[NSString class]])
		timestamp = object;
	else if ([object isKindOfClass:[NSDate class]])
		timestamp = [object timestampString];
	else {
		NSLog(@"DataModelUpdateManager:timestampForArray - Unexpected type in dictionary, wanted timestamp string, %@", [object description]);
	}

	[tempSorted release];
	return timestamp;
}
#endif

/*
- (NSArray *) localDataTimestamps {
	NSMutableArray *dataArray = [NSMutableArray array];
	
	NSArray *objects = [self.statusBlurbsAndModels allKeys];
	for (NSString *classString in objects) {
		if (NSClassFromString(classString)) {
			NSFetchRequest *request = [NSClassFromString(classString) fetchRequest];
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:JSONDATA_TIMESTAMPKEY ascending:NO];	// the most recent update will be the first item in the array (descending)
			[request setSortDescriptors:[NSArray arrayWithObject:desc]];
			[request setResultType:NSDictionaryResultType];												// This is necessary to limit it to specific properties during the fetch
			[request setPropertiesToFetch:[NSArray arrayWithObject:JSONDATA_TIMESTAMPKEY]];						// We don't want to fetch everything, we'll get a huge ass memory hit otherwise.
			[desc release];
			NSDictionary *vers = [[NSDictionary alloc] initWithObjectsAndKeys:
								  classString, JSONDATA_IDKEY,
								  [[NSClassFromString(classString) objectWithFetchRequest:request] valueForKey:JSONDATA_TIMESTAMPKEY], JSONDATA_TIMESTAMPKEY,
								  [NSString stringWithFormat:@"%@.json", classString], JSONDATA_FILEKEY,
								  nil];
			[dataArray addObject:vers];
			[vers release];
		}
	}
	
	NSSortDescriptor *idDesc = [[[NSSortDescriptor alloc] initWithKey:JSONDATA_IDKEY
								 ascending:YES
								  selector:@selector(localizedCompare:)] autorelease];
	[dataArray sortUsingDescriptors:[NSArray arrayWithObject:idDesc]];
	return dataArray;
}

- (NSArray *)remoteDataTimestamps {
	NSMutableArray *dataArray = nil;
	NSString *urlMethod = [NSString stringWithFormat:@"%@/%@", RESTKIT_BASE_URL, JSONDATA_TIMESTAMPFILE];
	NSURL *url = [NSURL URLWithString:urlMethod];

	if ([TexLegeReachability canReachHostWithURL:url alert:NO])
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

		NSError *error = nil;
		NSString * remoteVersionString = [NSString stringWithContentsOfURL:url encoding:JSONDATA_ENCODING error:&error];
		if (error) {
			NSLog(@"Error retrieving remote JSON data version file:%@", error);
		}
		if (remoteVersionString && [remoteVersionString length]) {
			NSArray *tempArray = [remoteVersionString JSONValue];
			if (!tempArray) {
				NSLog(@"Error parsing remote json data version string: %@", remoteVersionString);
			}
			else {
				dataArray = [NSMutableArray arrayWithArray:tempArray];
				NSSortDescriptor *idDesc = [[NSSortDescriptor alloc] initWithKey:JSONDATA_IDKEY ascending:YES selector:@selector(localizedCompare:)];
				[dataArray sortUsingDescriptors:[NSArray arrayWithObject:idDesc]];
				[idDesc release];
			}
		}
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	else
		NSLog(@"Network is unreachable, cannot obtain remote json data version file.");
	return dataArray;
}

- (NSArray *)deltaLocalTimestamps:(NSArray *)local toRemote:(NSArray *)remote {
	NSMutableArray *different = [NSMutableArray array];
#if TESTING
	for (NSDictionary *remoteItem in remote) {
		[different addObject:[remoteItem objectForKey:JSONDATA_IDKEY]];
	}
#else
	if (local && remote && ![local isEqualToArray:remote]) {
		BOOL localIsLarger = [local count] > [remote count];
		NSArray *larger = localIsLarger ? local : remote;
		NSArray *smaller = localIsLarger ? remote : local;
		
		for (NSDictionary *largerItem in larger) {
			NSString *largeID = [largerItem objectForKey:JSONDATA_IDKEY];
			NSString *largeStamp = [largerItem objectForKey:JSONDATA_TIMESTAMPKEY];
			BOOL wasFound = NO;
			for (NSDictionary *smallerItem in smaller) {
				NSString *smallID = [smallerItem objectForKey:JSONDATA_IDKEY];
				NSString *smallStamp = [smallerItem objectForKey:JSONDATA_TIMESTAMPKEY];
				if ([largeID isEqualToString:smallID]) {
					if (![largeStamp isEqualToString:smallStamp] ) {
						NSDictionary *remoteItem = nil; 
						if (localIsLarger)
							remoteItem = smallerItem;
						else
							remoteItem = largerItem;
						[different addObject:remoteItem];
					}
					wasFound = YES;
					break;
				}
			}
			if (!wasFound && !localIsLarger) {
				[different addObject:largerItem];
			}
		}
	}
#endif
	NSLog(@"DataModelUpdateManager: Found %d Differences in Local vs. Remote Data Timestamps", [different count]);
	return different;
}
*/

@end
