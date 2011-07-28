//
//  DistrictMapDataSource.h
//  Created by Gregory Combs on 8/23/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "TableDataSourceProtocol.h"

@interface DistrictMapDataSource : NSObject <TableDataSource>

@property (nonatomic, retain)	NSFetchedResultsController *fetchedResultsController;

@property (nonatomic)			NSInteger filterChamber;		// 0 means don't filter
@property (nonatomic, retain)	NSMutableString *filterString;	// @"" means don't filter
@property (nonatomic, readonly) BOOL hasFilter;
@property (nonatomic)			BOOL byDistrict;

- (void) setFilterByString:(NSString *)filter;
- (void) removeFilter;
- (IBAction) sortByType:(id)sender;

@end
