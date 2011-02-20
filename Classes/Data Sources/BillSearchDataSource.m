//
//  BillSearchViewController.m
//  TexLege
//
//  Created by Gregory Combs on 2/20/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//

#import "BillSearchDataSource.h"
#import "JSON.h"

@interface NSDictionary (BillIDComparison)
- (NSComparisonResult)compareBillsByID:(NSDictionary *)p;
@end
@implementation NSDictionary (BillIDComparison)
- (NSComparisonResult)compareBillsByID:(NSDictionary *)p
{	
	return [[self objectForKey:@"bill_id"] compare: [p objectForKey:@"bill_id"] options:NSNumericSearch];	
}
@end


@implementation BillSearchDataSource
@synthesize searchDisplayController;

- (id)initWithSearchDisplayController:(UISearchDisplayController *)newController; {
	if ([super init]) {
		_rows = [[NSMutableArray alloc] init];
		if (newController)
			searchDisplayController = [newController retain];
		
		_activeConnection = nil;
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section 
{		
	return [_rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"CellIdentifier";
	
	// Dequeue or create a cell of the appropriate type.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		//cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	// Configure the cell.
	NSDictionary *bill = [_rows objectAtIndex:indexPath.row];
	NSString *bill_id = [bill objectForKey:@"bill_id"];
	NSString *bill_title = [bill objectForKey:@"title"];
	if (!bill_title)
		bill_title = @"";
	
	cell.textLabel.text = bill_id;
	cell.detailTextLabel.text = bill_title;
	return cell;
}

- (void)startSearchWithString:(NSString *)searchString chamber:(NSInteger)chamber
{
	if (_activeConnection) {
		[_activeConnection cancel];
		[_activeConnection release];
		_activeConnection = nil;
	}
	
	//in the viewDidLoad
	if (_data) {
		[_data release];
		_data = nil;
	}
	
	_data = [[NSMutableData data] retain];
	NSString *baseurl = @"http://openstates.sunlightlabs.com/api/v1/bills/?search_window=session&state=tx&apikey=350284d0c6af453b9b56f6c1c7fea1f9";
	NSString *chamberString = @"lower";
	if (chamber == SENATE)
		chamberString = @"upper";
	
	if (!searchString)
		searchString = @"";
	
	searchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSString *endQuery = [NSString stringWithFormat:@"&chamber=%@&q=%@", chamberString, searchString];
	NSString *queryString = [NSString stringWithFormat:@"%@%@", baseurl, endQuery];
	
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryString]];//asynchronous call
	_activeConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] retain];
	
}

- (void)dealloc {
	[searchDisplayController release];
	[_rows release];
	if (_data)
		[_data release];
	if (_activeConnection) {
		[_activeConnection cancel];
		[_activeConnection release];
	}
 	[super dealloc];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    [_data release];
	_data = nil;
	
	[_rows removeAllObjects];
	[_rows addObjectsFromArray:[responseString JSONValue]];
	[responseString release];
    [connection release];

	[_rows sortUsingSelector:@selector(compareBillsByID:)];
	
	/* if we wanted blocks, we'd do this instead:
	 [_rows sortUsingComparator:^(NSDictionary *item1, NSDictionary *item2) {
		NSString *bill_id1 = [item1 objectForKey:@"bill_id"];
		NSString *bill_id2 = [item2 objectForKey:@"bill_id"];
		return [bill_id1 compare:bill_id2 options:NSNumericSearch];
	}];
	 */
	
	[self.searchDisplayController.searchResultsTableView reloadData];
	
}

@end


