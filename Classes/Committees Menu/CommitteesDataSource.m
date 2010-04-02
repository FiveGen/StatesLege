/*
 
 File: CommitteesDataSource.m
 Abstract: Provides the table view data for the elements sorted by atomic symbol.
 
 Version: 1.7
 
 */

#import "CommitteesDataSource.h"
#import "TexLegeAppDelegate.h"
#import "PeriodicElements.h"
#import "AtomicElement.h"
#import "AtomicElementTableViewCell.h"


@implementation CommitteesDataSource

// TableDataSourceProtocol methods

// return the data used by the navigation controller and tab bar item
- (NSString *)navigationBarName {
	return @"Committee Information";
}

- (NSString *)name {
	return @"Committees";
}


- (UIImage *)tabBarImage {
	return [UIImage imageNamed:@"60-signpost.png"];
}


- (BOOL)showDisclosureIcon
{
	return YES;
}


// atomic number is displayed in a plain style tableview
- (UITableViewStyle)tableViewStyle {
	return UITableViewStylePlain;
}


// return the atomic element at the index in the sorted by symbol array
- (AtomicElement *)cellDataForIndexPath:(NSIndexPath *)indexPath {
	
	return [[[PeriodicElements sharedPeriodicElements] elementsSortedBySymbol] objectAtIndex:indexPath.row];
}


// UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	AtomicElementTableViewCell *cell = (AtomicElementTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AtomicElementTableViewCell"];
	if (cell == nil) {
		cell = [[[AtomicElementTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"AtomicElementTableViewCell"] autorelease];
	}
    
	// configure cell contents
	// all the rows should show the disclosure indicator
	if ([self showDisclosureIcon])
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	// set the element for this cell as specified by the datasource. The cellDataForIndexPath: is declared
	// as part of the TableDataSource Protocol and will return the appropriate element for the index row
	cell.element = [self cellDataForIndexPath:indexPath];
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// this table has only one section
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {	
	// get the shared elements object
	// ask for, and return, the number of elements in the array of elements sorted by symbol
	
	return [[[PeriodicElements sharedPeriodicElements] elementsSortedBySymbol] count];
}


@end
