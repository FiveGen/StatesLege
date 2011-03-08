//
//  TexLegeCoreDataUtils.m
//  TexLege
//
//  Created by Gregory Combs on 8/31/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "TexLegeCoreDataUtils.h"
#import "LegislatorObj.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"
#import "DistrictMapObj.h"
#import "DistrictOfficeObj.h"
#import "StafferObj.h"
#import "WnomObj.h"
#import "LinkObj.h"
#import "TexLegeAppDelegate.h"
#import "NSDate+Helper.h"

@implementation TexLegeCoreDataUtils

+ (DistrictMapObj*)districtMapForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber {
	return [TexLegeCoreDataUtils districtMapForDistrict:district andChamber:chamber lightProperties:YES];
}

+ (DistrictMapObj*)districtMapForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber lightProperties:(BOOL)light {
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.district == %@ AND self.chamber == %@", district, chamber];
	return [TexLegeCoreDataUtils dataObjectWithPredicate:predicate entityName:@"DistrictMapObj" lightProperties:light];
}

+ (LegislatorObj*)legislatorForDistrict:(NSNumber*)district andChamber:(NSNumber*)chamber 
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.district == %@ AND self.legtype == %@", district, chamber];
	return [LegislatorObj objectWithPredicate:predicate];
}

+ (NSArray *) allLegislatorsSortedByPartisanshipFromChamber:(NSInteger)chamber andPartyID:(NSInteger)party
{
	if (chamber == BOTH_CHAMBERS) {
		debug_NSLog(@"allMembersByChamber: ... cannot be BOTH chambers");
		return nil;
	}
	
	NSFetchRequest *fetchRequest = [LegislatorObj fetchRequest];
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
	
	return [LegislatorObj objectsWithFetchRequest:fetchRequest];	
}

+ (id)dataObjectWithPredicate:(NSPredicate *)predicate entityName:(NSString*)entityName {
	return [TexLegeCoreDataUtils dataObjectWithPredicate:predicate entityName:entityName lightProperties:YES];
}

// You better make the predicate specific ... so that it only provides one result.  
+ (id)dataObjectWithPredicate:(NSPredicate *)predicate entityName:(NSString*)entityName lightProperties:(BOOL)light {
	if (!predicate || !entityName || !NSClassFromString(entityName))
		return nil;

	NSFetchRequest *request = [NSClassFromString(entityName) fetchRequest];
	if (light && [entityName isEqualToString:@"DistrictMapObj"])
		[request setPropertiesToFetch:[DistrictMapObj lightPropertiesToFetch]];
	[request setPredicate:predicate];
	
	return [NSClassFromString(entityName) objectWithFetchRequest:request];
}

+ (NSArray*)allObjectIDsInEntityNamed:(NSString*)entityName {
	if (entityName && NSClassFromString(entityName))
	{	
		NSFetchRequest *request = [NSClassFromString(entityName) fetchRequest];
		[request setResultType:NSManagedObjectIDResultType];	// only return object IDs
		return [NSClassFromString(entityName) objectsWithFetchRequest:request];	
	}
	return nil;
}


+ (NSArray *) allDistrictMapsLight {
	NSFetchRequest *fetchRequest = [DistrictMapObj fetchRequest];	
	[fetchRequest setPropertiesToFetch:[DistrictMapObj lightPropertiesToFetch]];
	return [DistrictMapObj objectsWithFetchRequest:fetchRequest];
}

+ (NSArray *)allDistrictMapIDsWithBoundingBoxesContaining:(CLLocationCoordinate2D)coordinate context:(NSManagedObjectContext *)context
{		
	NSNumber *lat = [NSNumber numberWithDouble:coordinate.latitude];
	NSNumber *lon = [NSNumber numberWithDouble:coordinate.longitude];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"maxLat >= %@ AND minLat <= %@ AND maxLon >=%@ AND minLon <= %@", lat, lat, lon, lon];
	
	NSFetchRequest *request = nil;
	if (!context) {
		request = [DistrictMapObj fetchRequest];
		[request setResultType:NSManagedObjectIDResultType];	// only return object IDs
		[request setPredicate:predicate];
		return [DistrictMapObj objectsWithFetchRequest:request];
	}
	else {
		request = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"DistrictMapObj" inManagedObjectContext:context];
		[request setEntity:entity];
		[request setResultType:NSManagedObjectIDResultType];	// only return object IDs
		[request setPredicate:predicate];
		NSError *error = nil;
		NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];
		[request release];
		if (error) {
			debug_NSLog(@"Problem fetching district maps IDs with bounding boxes containing coordinate.");
			return nil;
		}
		return fetchedObjects;
	}
}


+ (void) deleteAllObjectsInEntityNamed:(NSString*)entityName {
	debug_NSLog(@"I HOPE YOU REALLY WANT TO DO THIS ... DELETING ALL OBJECTS IN %@", entityName);
	debug_NSLog(@"----------------------------------------------------------------------");
	
	if (!entityName || !NSClassFromString(entityName))
		return;
	
	NSArray *fetchedObjects = [NSClassFromString(entityName) allObjects];
	if (fetchedObjects == nil) {
		debug_NSLog(@"There's no objects to delete ???");
	}
	
	for (NSManagedObject *object in fetchedObjects) {
		[[NSClassFromString(entityName) managedObjectContext] deleteObject:object];
	}
}

+ (void)loadDataFromRest:(NSString *)entityName delegate:(id)delegate {
	if (!entityName || !NSClassFromString(entityName))
		return;
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	NSString *resourcePath = [NSString stringWithFormat:@"/%@.json", entityName];
	[objectManager loadObjectsAtResourcePath:resourcePath objectClass:NSClassFromString(entityName) delegate:delegate];
//	[[objectManager objectStore] save];
}

+ (void)initRestKitObjects:(id)sender {
	
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RESTKIT_BASE_URL];
	RKObjectMapper* mapper = objectManager.mapper;
	// Initialize object store
	NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"TexLege" ofType:@"momd"];
	NSURL *momURL = [NSURL fileURLWithPath:modelPath];
	NSManagedObjectModel *mom = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momURL] autorelease];
		
	// Add our element to object mappings
	[mapper registerClass:[LegislatorObj class] forElementNamed:@"legislators"];
	[mapper registerClass:[CommitteeObj class] forElementNamed:@"committees"];
	[mapper registerClass:[CommitteePositionObj class] forElementNamed:@"committeePositions"];
	[mapper registerClass:[DistrictMapObj class] forElementNamed:@"districtMaps"];
	[mapper registerClass:[DistrictOfficeObj class] forElementNamed:@"districtOffices"];
	[mapper registerClass:[LinkObj class] forElementNamed:@"links"];
	[mapper registerClass:[StafferObj class] forElementNamed:@"staffers"];
	[mapper registerClass:[WnomObj class] forElementNamed:@"wnomScores"];
	
	// Update date format so that we can parse twitter dates properly
	// Wed Sep 29 15:31:08 +0000 2010
	NSMutableArray* dateFormats = [[[mapper dateFormats] mutableCopy] autorelease];
	[dateFormats addObject:@"E MMM d HH:mm:ss Z y"];
	[dateFormats addObject:[NSDate dateFormatString]];
	[dateFormats addObject:[NSDate timeFormatString]];
	[dateFormats addObject:[NSDate timestampFormatString]];
	[mapper setDateFormats:dateFormats];
		
	// Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.
	
#ifdef RESTKIT_GENERATE_SEED_DB
	// Initialize object store
    objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"TexLegeSeed.sqlite" 
															 usingSeedDatabaseName:nil /// this is stupid ... we can't supply it yet.
																managedObjectModel:mom];
	
    RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
    [seeder seedObjectsFromFile:@"LegislatorObj.json" toClass:[LegislatorObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"DistrictMapObj.json" toClass:[DistrictMapObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"CommitteeObj.json" toClass:[CommitteeObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"CommitteePositionObj.json" toClass:[CommitteePositionObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"DistrictOfficeObj.json" toClass:[DistrictOfficeObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"StafferObj.json" toClass:[StafferObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"WnomObj.json" toClass:[WnomObj class] keyPath:nil];
    [seeder seedObjectsFromFile:@"LinkObj.json" toClass:[LinkObj class] keyPath:nil];
    
	for (DistrictMapObj *map in [DistrictMapObj allObjects])
		[map resetRelationship:self];

    // Finalize the seeding operation and output a helpful informational message
    [seeder finalizeSeedingAndExit];
    
    // NOTE: If all of your mapped objects use element -> class registration, you can perform seeding in one line of code:
    // [RKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
#endif
	
	objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"TexLege.sqlite" 
															 usingSeedDatabaseName:@"TexLegeSeed.sqlite" 
																managedObjectModel:mom];
}

@end

