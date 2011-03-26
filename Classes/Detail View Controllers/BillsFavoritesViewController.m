//
//  BillsFavoritesViewController.m
//  TexLege
//
//  Created by Gregory Combs on 2/25/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//

#import "TexLegeAppDelegate.h"
#import "BillsFavoritesViewController.h"
#import "BillsDetailViewController.h"
#import <RestKit/Support/JSON/JSONKit/JSONKit.h>
#import "UtilityMethods.h"
#import "TexLegeTheme.h"
#import "DisclosureQuartzView.h"
#import "OpenLegislativeAPIs.h"

@interface BillsFavoritesViewController (Private)
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (IBAction)save:(id)sender;
- (NSString *)watchIDForBill:(NSDictionary *)aBill;
@end

@implementation BillsFavoritesViewController


#pragma mark -
#pragma mark View lifecycle

/*
- (void)didReceiveMemoryWarning {
	[_cachedBills release];
	_cachedBills = nil;	
}*/

- (void)viewDidLoad {
	[super viewDidLoad];
		
	NSString *myClass = NSStringFromClass([self class]);
	NSArray *menuArray = [UtilityMethods texLegeStringWithKeyPath:@"BillMenuItems"];
	NSDictionary *menuItem = [menuArray findWhereKeyPath:@"class" equals:myClass];
	
	if (menuItem)
		self.title = [menuItem objectForKey:@"title"];
	//self.navigationController.navigationItem.rightBarButtonItem
	[[self navigationItem] setRightBarButtonItem:[self editButtonItem] animated:YES];
	
	self.tableView.separatorColor = [TexLegeTheme separator];
	self.tableView.backgroundColor = [TexLegeTheme tableBackground];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	
	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:thePath]) {
		NSArray *tempArray = [[NSArray alloc] init];
		[tempArray writeToFile:thePath atomically:YES];
		[tempArray release];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (_watchList) {
		[_watchList release];
		_watchList = nil;
	}
	NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
	_watchList = [[[NSMutableArray alloc] initWithContentsOfFile:thePath] retain];
	if (!_watchList)
		_watchList = [[[NSMutableArray alloc] init] retain];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
	[_watchList sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];	
	
	if (![_watchList count]) {
		UIAlertView *noWatchedBills = [[[ UIAlertView alloc ] 
										 initWithTitle:[UtilityMethods texLegeStringWithKeyPath:@"Bills.NoWatchedTitle"] 
										 message:[UtilityMethods texLegeStringWithKeyPath:@"Bills.NoWatchedText"] 
										 delegate:nil // we're static, so don't do "self"
										 cancelButtonTitle: @"Cancel" 
										 otherButtonTitles:nil, nil] autorelease];
		[ noWatchedBills show ];		
		
	}
	[self.tableView reloadData];
	
	[self loadBills:nil];

}

/*- (void)viewWillDisappear:(BOOL)animated {
//	[self save:nil];
	[super viewWillDisappear:animated];
}*/

- (NSString *)watchIDForBill:(NSDictionary *)aBill {
	if (aBill && [aBill objectForKey:@"session"] && [aBill objectForKey:@"bill_id"])
		return [NSString stringWithFormat:@"%@:%@", [aBill objectForKey:@"session"],[aBill objectForKey:@"bill_id"]]; 
	else
		return @"";
}

- (IBAction)loadBills:(id)sender {
	if (_cachedBills) {
		[_cachedBills release];
		_cachedBills = nil;
	}
	
	_cachedBills = [[[NSMutableDictionary alloc] init] retain];
	
	for (NSDictionary *item in _watchList) {
		[[OpenLegislativeAPIs sharedOpenLegislativeAPIs] queryOpenStatesBillWithID:[item objectForKey:@"name"] 
																		   session:[item objectForKey:@"session"] 
																		  delegate:self];
	}	
}

- (IBAction)save:(id)sender {
	if (_watchList) {
		NSString *thePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent:kBillFavoritesStorageFile];
		[_watchList writeToFile:thePath atomically:YES];		
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
	
	cell.textLabel.text = [[_watchList objectAtIndex:indexPath.row] objectForKey:@"name"];
	cell.detailTextLabel.text = [[_watchList objectAtIndex:indexPath.row] objectForKey:@"description"];	
}

#pragma mark -
#pragma mark Table view data source

- (void)tableView:(UITableView *)aTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	BOOL useDark = (indexPath.row % 2 == 0);
	cell.backgroundColor = useDark ? [TexLegeTheme backgroundDark] : [TexLegeTheme backgroundLight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (_watchList && [_watchList count])
		return [_watchList count];
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *CellIdentifier = @"CellOff";
	if (_watchList && [_watchList count] > indexPath.row) {
		NSString *watchID = [[_watchList objectAtIndex:indexPath.row] objectForKey:@"watchID"];
		if (_cachedBills && [[_cachedBills allKeys] containsObject:watchID])
			CellIdentifier = @"CellOn";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
									   reuseIdentifier:CellIdentifier] autorelease];
		
		cell.textLabel.textColor =	[TexLegeTheme textDark];
		cell.textLabel.textAlignment = UITextAlignmentLeft;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
		
		if ([CellIdentifier isEqualToString:@"CellOff"])
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		else {
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.textLabel.adjustsFontSizeToFitWidth = YES;
			cell.textLabel.minimumFontSize = 12.0f;
			DisclosureQuartzView *qv = [[DisclosureQuartzView alloc] initWithFrame:CGRectMake(0.f, 0.f, 28.f, 28.f)];
			cell.accessoryView = qv;
			[qv release];			
		}

    }
	
	if (_watchList && [_watchList count])
		[self configureCell:cell atIndexPath:indexPath];		
	
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSDictionary *toRemove = [_watchList objectAtIndex:indexPath.row];
		if (toRemove && _cachedBills) {
			NSString *watchID = [toRemove objectForKey:@"watchID"];
			if (watchID && [[_cachedBills allKeys] containsObject:watchID])
				[_cachedBills removeObjectForKey:watchID];
		}
		[_watchList removeObjectAtIndex:indexPath.row];
		[self save:nil];		
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
	}   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath 
      toIndexPath:(NSIndexPath *)destinationIndexPath;
{  	
	if (!_watchList)
		return;
	
	NSDictionary *item = [[_watchList objectAtIndex:sourceIndexPath.row] retain];	
	[_watchList removeObject:item];
	[_watchList insertObject:item atIndex:[destinationIndexPath row]];	
	[item release];
	
	int i = 0;
	for (NSMutableDictionary *anItem in _watchList)
		[anItem setValue:[NSNumber numberWithInt:i++] forKey:@"displayOrder"];
	
	[self save:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (!_watchList)
		return;
	
	NSDictionary *item = [_watchList objectAtIndex:indexPath.row];
	if (item && [item objectForKey:@"watchID"]) {
		NSMutableDictionary *bill = [_cachedBills objectForKey:[item objectForKey:@"watchID"]];
		if (bill) {
			BOOL changingViews = NO;
			
			BillsDetailViewController *detailView = nil;
			if ([UtilityMethods isIPadDevice]) {
				id aDetail = [[[TexLegeAppDelegate appDelegate] detailNavigationController] visibleViewController];
				if ([aDetail isKindOfClass:[BillsDetailViewController class]])
					detailView = aDetail;
			}
			if (!detailView) {
				detailView = [[[BillsDetailViewController alloc] 
													  initWithNibName:@"BillsDetailViewController" bundle:nil] autorelease];
				changingViews = YES;
			}
						
			[detailView setDataObject:bill];
			if (![UtilityMethods isIPadDevice])
				[self.navigationController pushViewController:detailView animated:YES];
			else if (changingViews)
				[[[TexLegeAppDelegate appDelegate] detailNavigationController] setViewControllers:[NSArray arrayWithObject:detailView] animated:NO];
			
		}			
	}
}

- (void)dealloc {	
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];

	if (_watchList) {
		[_watchList release];
		_watchList = nil;
	}
	if (_cachedBills) {
		[_cachedBills release];
		_cachedBills = nil;
	}
	
	[super dealloc];
}

#pragma mark -
#pragma mark RestKit:RKObjectLoaderDelegate

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if (error && request) {
		debug_NSLog(@"BillFavorites - Error loading bill results from %@: %@", [request description], [error localizedDescription]);
		//[[NSNotificationCenter defaultCenter] postNotificationName:kBillSearchNotifyDataError object:nil];
	}
}


- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
	if ([request isGET] && [response isOK]) {  
		// Success! Let's take a look at the data  
		
		NSMutableDictionary *object = [response.body mutableObjectFromJSONData];
		if (object && _cachedBills) {
			NSString *watchID = [self watchIDForBill:object];
			[_cachedBills setObject:object forKey:watchID];
			
			NSInteger row = 0;
			NSInteger index = 0;
			for (NSDictionary *search in _watchList) {
				if ([[search objectForKey:@"watchID"] isEqualToString:watchID]) {
					row = index;
					break;
				}
				index++;
			}
			NSIndexPath *rowPath = [NSIndexPath indexPathForRow:row inSection:0];
			//[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:rowPath] withRowAnimation:UITableViewRowAnimationMiddle];
			if (row+1 > [_watchList count])
				[self.tableView reloadData];
			else
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:rowPath] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
}


@end


