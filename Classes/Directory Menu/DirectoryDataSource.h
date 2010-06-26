//
//  DirectoryDataSource.m
//  TexLege
//
//  Created by Gregory S. Combs on 5/31/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//


#import "Constants.h"
#import "TableDataSourceProtocol.h"
#import "LegislatorObj.h"

@interface DirectoryDataSource : NSObject <UITableViewDataSource,TableDataSource, NSFetchedResultsControllerDelegate>  {
	BOOL hideTableIndex;
	NSInteger filterChamber;
	NSMutableString *filterString;
	
	//NSMutableDictionary *imageCache;
	
	NSFetchedResultsController *fetchedResultsController;
	NSManagedObjectContext *managedObjectContext;	
}
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) NSInteger filterChamber;		// 0 means don't filter
@property (nonatomic,retain) NSMutableString *filterString;	// @"" means don't filter
@property (nonatomic, readonly) BOOL hasFilter;
//@property (nonatomic, retain) NSMutableDictionary *imageCache;

- (LegislatorObj *)legislatorDataForIndexPath:(NSIndexPath *)indexPath;
- (void) setFilterByString:(NSString *)filter;
- (void) removeFilter;

#if NEEDS_TO_INITIALIZE_DATABASE
- (void)initializeDatabase;	
#endif

@end
