//
//  LegislatorDetailViewController.m
//  TexLege
//
//  Created by Gregory Combs on 6/28/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "LegislatorDetailViewController.h"
#import "LegislatorObj.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"

#import "StaticGradientSliderView.h"
#import "UtilityMethods.h"
#import "TableDataSourceProtocol.h"
#import "DirectoryDetailInfo.h"
#import "NotesViewController.h"
#import "TexLegeAppDelegate.h"

#import "CommitteeDetailViewController.h"

#import "MiniBrowserController.h"
#import "MapsDetailViewController.h"

@interface LegislatorDetailViewController (Private)
@property (nonatomic, retain) UIPopoverController *popoverController;

- (void) pushMapViewWithURL:(NSURL *)url;
- (void) showWebViewWithURL:(NSURL *)url;
- (void) setupHeaderView;
- (void) setupHeader;
- (void) createSectionList;

@end


@implementation LegislatorDetailViewController

@synthesize legislator, sectionArray;
@synthesize startupSplashView, headerView;

@synthesize popoverController;
@synthesize scatterPlotView, dataForPlot; //, dataForChart;

@synthesize leg_photoView, leg_partyLab, leg_districtLab, leg_tenureLab, leg_nameLab;
@synthesize indivSlider, partySlider, allSlider;
@synthesize indivPHolder, partyPHolder, allPHolder;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	[self constructScatterPlot];
	
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	//self.navigationItem.rightBarButtonItem = self.editButtonItem;

}

- (void)setupHeaderView {
	if (self.headerView == nil && self.scatterPlotView) {
		UIView * headerSuper = self.scatterPlotView.superview;
		
		NSString * headerViewXib = [UtilityMethods isIPadDevice] ? @"LegislatorDetailHeaderView~ipad" : @"LegislatorDetailHeaderView~iphone";
		
		
		// Load one of our header views (iPad or iPhone selected automatically by the file's name extension
		if (self.headerView == nil) {
			NSArray *objects = [[NSBundle mainBundle] loadNibNamed:headerViewXib owner:self options:NULL];
			self.headerView = [objects objectAtIndex:0];
		}
		if ([UtilityMethods isIPadDevice] == NO) {
			CGFloat headerHeight = self.scatterPlotView.bounds.size.height+self.headerView.bounds.size.height;
			[headerSuper setBounds:CGRectMake(0.0f, 0.0f, headerSuper.bounds.size.width, headerHeight)];
	
		}			
		[headerSuper insertSubview:self.headerView aboveSubview:self.scatterPlotView];
	}
}
	
- (void)setupHeader {
	[self setupHeaderView];
	
	NSString *legName = [NSString stringWithFormat:@"%@ %@",  [self.legislator legTypeShortName], [self.legislator legProperName]];
	self.leg_nameLab.text = legName;
	self.navigationItem.title = legName;

	self.leg_photoView.image = [UtilityMethods poorMansImageNamed:self.legislator.photo_name];
	self.leg_partyLab.text = [self.legislator party_name];
	self.leg_districtLab.text = [NSString stringWithFormat:@"District %@", self.legislator.district];
	self.leg_tenureLab.text = [self.legislator tenureString];

	if ([UtilityMethods isIPadDevice] && self.indivSlider == nil) {
		NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"StaticGradientSliderView" owner:self options:NULL];
		for (id suspect in objects) {
			if ([suspect isKindOfClass:[StaticGradientSliderView class]]) {
				self.indivSlider = suspect;
			}
		}
		CGRect sliderViewFrame = indivPHolder.bounds;
		[self.indivSlider setFrame:sliderViewFrame];
		[self.indivSlider.sliderControl setThumbImage:[UIImage imageNamed:@"slider_star_big.png"] forState:UIControlStateNormal];
		[indivPHolder addSubview:self.indivSlider];
		if (self.indivSlider) {
			self.indivSlider.sliderValue = self.legislator.partisan_index.floatValue;
		}	
	}
}

- (void)setLegislator:(LegislatorObj *)newLegislator {
	if (self.startupSplashView) {
		[self.startupSplashView removeFromSuperview];
	}
	if (legislator) [legislator release], legislator = nil;
	if (newLegislator) {
		legislator = [newLegislator retain];
		
		[self setupHeader];
		
		if (self.popoverController != nil) {
			[self.popoverController dismissPopoverAnimated:YES];
			//self.popoverController = nil; // i think this breaks, unless you're in a showHide type of situation.
		}        
		
		[self createSectionList];
		
		[self.tableView reloadData];
		[self.view setNeedsDisplay];
	}
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	if (self.legislator)
		[self setupHeader];
	
	// we don't have a legislator selected and yet we're appearing in portrait view ... got to have something here !!! 
	if (self.legislator == nil && ![UtilityMethods isLandscapeOrientation])  {
		NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"StartupSplashView-Portrait" owner:self options:NULL];
		self.startupSplashView = [objects objectAtIndex:0];
		[self.view addSubview:self.startupSplashView];
		//[self.view setNeedsDisplay];
		
#if 0
		// We could alternatively use this opportunity to open a proper informational introduction
		// for instance, drop in a new view taking the full screen that discusses stuff (and points them to rotate the device)
		
		// or we could figure out how to force this to start in a landscape view...
		
		id<TableDataSource> masterDataSource = nil;
		UINavigationController *masterNavControl = [self.splitViewController.viewControllers objectAtIndex:0];
		UIViewController *suspectVC = masterNavControl.topViewController;
		if ([suspectVC respondsToSelector:@selector(dataSource)])
			masterDataSource = [suspectVC performSelector:@selector(dataSource)];
		
		if (masterDataSource) {
			NSUInteger ints[2] = {0,0};	// just pick the first legislator in our datasource
			NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:ints length:2];
			//[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
			self.legislator = [masterDataSource legislatorDataForIndexPath:indexPath];
		}
#endif
	}
	else {
		[self.startupSplashView removeFromSuperview];
	}

}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController: (UIPopoverController*)pc {
	
	barButtonItem.title = @"Legislators";	
	[self.navigationItem setRightBarButtonItem:[barButtonItem retain] animated:YES];
	//[self.navigationController setNavigationBarHidden:NO animated:YES];
	
    self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	
	self.navigationItem.rightBarButtonItem = nil;
	//[self.navigationController setNavigationBarHidden:YES animated:NO];

	self.popoverController = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
    if (pc != nil) {
        [pc dismissPopoverAnimated:YES];
		// do I need to set pc to nil?  I need to confirm, but I think it breaks things.
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

/*
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if (UIInterfaceOrientationIsLandscape(fromInterfaceOrientation))
	{
		// Move the plots into place for portrait
		//scatterPlotView.frame = CGRectMake(20.0f, 55.0f, 728.0f, 556.0f);
		//barChartView.frame = CGRectMake(20.0f, 644.0f, 340.0f, 340.0f);
		//pieChartView.frame = CGRectMake(408.0f, 644.0f, 340.0f, 340.0f);
	}
	else
	{
		// Move the plots into place for landscape
		//scatterPlotView.frame = CGRectMake(20.0f, 51.0f, 628.0f, 677.0f);
		//barChartView.frame = CGRectMake(684.0f, 51.0f, 320.0f, 320.0f);
		//pieChartView.frame = CGRectMake(684.0f, 408.0f, 320.0f, 320.0f);
	}
}
*/

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.popoverController = nil;
	self.sectionArray = nil;
	//self.toolbar = nil;
	
	self.indivSlider = self.partySlider = self.allSlider = nil;
	self.indivPHolder = self.partyPHolder = self.allPHolder = nil;
	self.legislator = nil;
	self.leg_photoView = nil;
	self.leg_partyLab = self.leg_districtLab = self.leg_tenureLab = self.leg_nameLab = nil;
	self.headerView = self.startupSplashView = nil;

}


- (void)dealloc {
	self.dataForPlot = nil;
	//self.dataForChart = nil;
    [super dealloc];
}



#pragma mark -
#pragma mark Table view data source

- (void) createSectionList {
	NSInteger numberOfSections = 3 + [self.legislator numberOfDistrictOffices];	
	NSString *tempString = nil;
	BOOL isPhone = [UtilityMethods canMakePhoneCalls];
	DirectoryDetailInfo *cellInfo = nil;
	
	// create an array of sections, with arrays of DirectoryDetailInfo entries as contents
	if (self.sectionArray) {
		// is this necessary???
		for (NSMutableArray *entryArray in self.sectionArray)
			[entryArray removeAllObjects];
		self.sectionArray = nil;	// this calls removeAllObjects and release automatically
	}
	self.sectionArray = [NSMutableArray arrayWithCapacity:numberOfSections];

	NSInteger i;
	for (i=0; i < numberOfSections; i++) {
		NSMutableArray *entryArray = [[NSMutableArray alloc] initWithCapacity:20]; // just an arbitrary maximum
		[self.sectionArray addObject:entryArray];
		[entryArray release], entryArray = nil;
	}
	
	
	/*	Section 0: Personal Information */		
	NSInteger sectionIndex = 0;	
	
	cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Name" value:[self.legislator fullName] 
											isClickable:NO type:DirectoryTypeNone];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Website" value:self.legislator.website 
											 isClickable:YES type:DirectoryTypeWeb];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Bio" value:self.legislator.bio_url 
											 isClickable:YES type:DirectoryTypeWeb];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Email" value:self.legislator.email 
											 isClickable:YES type:DirectoryTypeMail];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	if (self.legislator.twitter.length > 0) {
		tempString = [[NSString alloc] initWithFormat:@"@%@", self.legislator.twitter];
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Twitter" value: tempString
															   isClickable:YES type:DirectoryTypeTwitter];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
		[tempString release], tempString = nil;
	}
	
	
	if ([UtilityMethods isIPadDevice] == NO && self.legislator.partisan_index.floatValue != 0.0f) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Index" value:[self.legislator.partisan_index description] 
												 isClickable:NO type:DirectoryTypeIndex];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;

		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"" value:@"About the Roll Call Index" 
												 isClickable:YES type:DirectoryTypeIndexAbout];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	
	
	if (self.legislator.notes.length > 0)
		tempString = self.legislator.notes;
	else
		tempString = kStaticNotes;
	
	cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Notes" value: tempString
											 isClickable:YES type:DirectoryTypeNotes];
	[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	[cellInfo release], cellInfo = nil;
	
	
	/* after that section's done... DO COMMITTEES */
	sectionIndex++;
	for (CommitteePositionObj *position in [self.legislator sortedCommitteePositions]) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:[position positionString] value:[position.committee committeeName] 
												 isClickable:YES type:DirectoryTypeCommittee];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;
	}
	
	/* Now we handle all the office locations ... */
	sectionIndex++;
	/*	Section 1: Capitol Office */		
	
	if (legislator.staff.length > 0) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Staff" value:self.legislator.staff 
												 isClickable:NO type:DirectoryTypeNone];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	}
	if (self.legislator.cap_office.length > 0) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Office" value:self.legislator.cap_office 
												 isClickable:YES type:DirectoryTypeOfficeMap];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	} 
	if (legislator.chamber_desk.length > 0) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Desk #" value:self.legislator.chamber_desk 
												 isClickable:YES type:DirectoryTypeChamberMap];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	}
	if (legislator.cap_phone.length > 0) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Phone" value:self.legislator.cap_phone 
												 isClickable:isPhone type:DirectoryTypePhone];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	} 
	if (legislator.cap_fax.length > 0) {
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Fax" value:self.legislator.cap_fax 
												 isClickable:NO type:DirectoryTypeNone];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	}
	if (legislator.cap_phone2.length > 0) {
		tempString = (self.legislator.cap_phone2_name.length > 0) ? self.legislator.cap_phone2_name : @"Phone #2";
		cellInfo = [[DirectoryDetailInfo alloc] initWithName:tempString value:self.legislator.cap_phone2 
												 isClickable:isPhone type:DirectoryTypePhone];
		[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
		[cellInfo release], cellInfo = nil;		
	} 
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 1) {
		sectionIndex++;
		/*	Section 2: District 1 */		
		
		if (legislator.dist1_phone.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Phone" value:self.legislator.dist1_phone 
													 isClickable:isPhone type:DirectoryTypePhone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;		
		} 
		if (legislator.dist1_fax.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Fax" value:self.legislator.dist1_fax 
													 isClickable:NO type:DirectoryTypeNone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}
		if (legislator.dist1_street.length > 0) {
			tempString = [[NSString alloc] initWithFormat:@"%@\n%@, TX\n%@", 
						  [self.legislator.dist1_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"], 
						  self.legislator.dist1_city, self.legislator.dist1_zip];
			
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Address" value:tempString 
													 isClickable:YES type:DirectoryTypeMap];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
			[tempString release], tempString = nil;
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 2) {
		sectionIndex++;
		/*	Section 3: District 2 */		
		
		if (legislator.dist2_phone.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Phone" value:self.legislator.dist2_phone 
													 isClickable:isPhone type:DirectoryTypePhone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		} 
		if (legislator.dist2_fax.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Fax" value:self.legislator.dist2_fax 
													 isClickable:NO type:DirectoryTypeNone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}
		if (legislator.dist2_street.length > 0) {
			tempString = [[NSString alloc] initWithFormat:@"%@\n%@, TX\n%@", 
						  [self.legislator.dist2_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"], 
						  self.legislator.dist2_city, self.legislator.dist2_zip];
			
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Address" value:tempString 
													 isClickable:YES type:DirectoryTypeMap];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
			[tempString release], tempString = nil;
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 3) {
		sectionIndex++;
		/*	Section 4: District 3 */		
		
		if (legislator.dist3_phone1.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Phone" value:self.legislator.dist3_phone1 
													 isClickable:isPhone type:DirectoryTypePhone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;			
		} 
		if (legislator.dist3_fax.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Fax" value:self.legislator.dist3_fax 
													 isClickable:NO type:DirectoryTypeNone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}
		if (legislator.dist3_street.length > 0) {
			tempString = [[NSString alloc] initWithFormat:@"%@\n%@, TX\n%@", 
						  [self.legislator.dist3_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"], 
						  self.legislator.dist3_city, self.legislator.dist3_zip];
			
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Address" value:tempString 
													 isClickable:YES type:DirectoryTypeMap];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
			[tempString release], tempString = nil;
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 4) {
		sectionIndex++;
		/*	Section 5: District 4 */		
		
		if (legislator.dist4_phone1.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Phone" value:self.legislator.dist4_phone1 
													 isClickable:isPhone type:DirectoryTypePhone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;						
		} 
		if (legislator.dist4_fax.length > 0) {
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Fax" value:self.legislator.dist4_fax 
													 isClickable:NO type:DirectoryTypeNone];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
		}
		if (legislator.dist4_street.length > 0) {
			tempString = [[NSString alloc] initWithFormat:@"%@\n%@, TX\n%@", 
						  [self.legislator.dist4_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"], 
						  self.legislator.dist4_city, self.legislator.dist4_zip];
			
			cellInfo = [[DirectoryDetailInfo alloc] initWithName:@"Address" value:tempString 
													 isClickable:YES type:DirectoryTypeMap];
			[[self.sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
			[cellInfo release], cellInfo = nil;
			[tempString release], tempString = nil;
		} 
	}
}	

#pragma mark -
#pragma mark Custom Slider

/* This determines the appropriate size for the custom slider view, given its superview */
- (CGRect) preshrinkSliderViewFromView:(UIView *)aView {
	CGFloat sliderHeight = 24.0f;
	CGFloat sliderInset = 18.0f;
	
	CGRect rect = aView.bounds;
	CGFloat sliderWidth = aView.bounds.size.width - (sliderInset * 2);
	
	rect.origin.y = aView.center.y - (sliderHeight / 2);
	rect.size.height = sliderHeight;
	rect.origin.x = sliderInset; //aView.center.x - (sliderWidth / 2);
	rect.size.width = sliderWidth;
	
	return rect;
}

#pragma mark -
#pragma mark UITableViewDataSource methods


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{		
	//DirectoryDetailInfo * cellInfo = [[DirectoryDetailInfo alloc] init];
	//[self infoForRow:cellInfo atIndexPath:indexPath];
	
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
	
	DirectoryDetailInfo *cellInfo = nil;
	NSMutableArray *entryArray = [self.sectionArray objectAtIndex:section];
	if (entryArray)
		cellInfo = [entryArray objectAtIndex:row];
	
	if (cellInfo == nil) {
		NSLog(@"LegislatorDetailViewController:cellForRow: error finding table entry for section:%d row:%d", section, row);
		 return nil;
	}
		 
	BOOL clickable = clickable = cellInfo.isClickable;
	//NSString *CellIdentifier = [NSString stringWithFormat:@"Section: %d Row: %d",indexPath.section,indexPath.row];
	NSString *CellIdentifier = [NSString stringWithFormat:@"Type: %d",cellInfo.entryType];
	//NSString *CellIdentifier = @"DirectoryDetailCell";
	
	/* Look up cell in the table queue */
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	UITableViewCellStyle currentStyle = UITableViewCellStyleValue2;
	UITableViewCellSelectionStyle selectionStyle = clickable ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
	
	/* Not found in queue, create a new cell object */
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:currentStyle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	cell.selectionStyle = selectionStyle;
	if (clickable)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
	
	switch(cellInfo.entryType) {
		case DirectoryTypeNotes:		// Since our notes data can change, we must tend to the cached info ...
			if (self.legislator.notes.length > 0)
				cell.detailTextLabel.textColor = [UIColor blackColor];
			else
				cell.detailTextLabel.textColor = [UIColor grayColor];
			cell.detailTextLabel.text = cellInfo.entryValue;
			cell.textLabel.text = cellInfo.entryName;
			break;
			
		case DirectoryTypeIndexAbout:  // About the Partisanship Index...
			if (![UtilityMethods isIPadDevice]) {
				cell.detailTextLabel.textColor = [UIColor colorWithRed:56.0/256.0 green:84/256.0 blue:135/256.0 alpha:1.0];
				cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14];
				cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
				cell.detailTextLabel.text = cellInfo.entryValue;
				cell.textLabel.text = cellInfo.entryName;
			}
			break;
			
		case DirectoryTypeIndex:		// partisan index custom slider
			if (![UtilityMethods isIPadDevice]) {
				cell.textLabel.opaque = NO;
				cell.textLabel.numberOfLines = 2;
				cell.textLabel.highlightedTextColor = [UIColor blackColor];
				//cell.textLabel.text = cellInfo.entryName;
				
				CGRect sliderViewFrame = [self preshrinkSliderViewFromView:cell.contentView];
				if (self.indivSlider == nil) {
					NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"StaticGradientSliderView" owner:self options:NULL];
					for (id suspect in objects) {
						if ([suspect isKindOfClass:[StaticGradientSliderView class]]) {
							self.indivSlider = suspect;
						}
					}
				}
				if (self.indivSlider) {
					[self.indivSlider setFrame:sliderViewFrame];
					self.indivSlider.sliderValue = cellInfo.entryValue.floatValue;
					[cell.contentView addSubview:self.indivSlider];
				}
				cell.userInteractionEnabled = NO;
			}
			break;
			
		case DirectoryTypeMap:
			cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
			cell.detailTextLabel.numberOfLines = 4;
			cell.detailTextLabel.text = cellInfo.entryValue;
			cell.textLabel.text = cellInfo.entryName;
			break;
			
		case DirectoryTypeWeb:
			if (cellInfo.entryValue.length > 0) {
				if ([cellInfo.entryName isEqualToString:@"Website"])
					cell.detailTextLabel.text = @"Official Website";
				else if ([cellInfo.entryName isEqualToString:@"Bio"])
					cell.detailTextLabel.text = @"VoteSmart Bio";
				cell.textLabel.text = @"Web";
			}
			break;
			
		case DirectoryTypeCommittee:
		case DirectoryTypeOfficeMap:
		case DirectoryTypeChamberMap:
		case DirectoryTypeTwitter:
		case DirectoryTypeMail:
		case DirectoryTypePhone:
		case DirectoryTypeSMS:
		case DirectoryTypeNone:
			cell.detailTextLabel.text = cellInfo.entryValue;
			cell.textLabel.text = cellInfo.entryName;
			break;
			
		default:
			cell.autoresizingMask = UIViewAutoresizingFlexibleHeight;
			cell.hidden = YES;
			cell.frame  = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, 0.01f, 0.01f);
			cell.tag = 999; //EMPTY
			[cell sizeToFit];
			break;
	}
	
	[cell sizeToFit];
	[cell setNeedsDisplay];
	
	return cell;
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [sectionArray count];
	
}


- (NSInteger)tableView:(UITableView *)tableView  numberOfRowsInSection:(NSInteger)section {		
	return [[sectionArray objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {	
	if (section == 0)
		return @"Legislator Information";
	else if (section == 1)
		return @"Committee Assignments";
	else if (section == 2)
		return @"Capitol Office";
	else if (section == 3)
		return @"District Office #1";
	else if (section == 4)
		return @"District Office #2";
	else if (section == 5)
		return @"District Office #3";
	else //if (section == 6)
		return @"District Office #4";
}


// the user selected a row in the table.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	int row = [newIndexPath row];
	int section = [newIndexPath section];
	
	// deselect the new row using animation
	[tableView deselectRowAtIndexPath:newIndexPath animated:YES];	
	
	DirectoryDetailInfo *cellInfo = nil;
	NSMutableArray *entryArray = [self.sectionArray objectAtIndex:section];
	if (entryArray)
		cellInfo = [entryArray objectAtIndex:row];
	
	if (cellInfo == nil) {
		NSLog(@"LegislatorDetailViewController:didSelectRow: error finding table entry for section:%d row:%d", section, row);
		return;
	}
	
	if (cellInfo.isClickable) {
		if (cellInfo.entryType == DirectoryTypeIndexAbout) {
			TexLegeAppDelegate *appDelegate = (TexLegeAppDelegate *)[[UIApplication sharedApplication] delegate];
			if (appDelegate != nil) [appDelegate showVoteInfoDialog:self];
		}
		else if (cellInfo.entryType == DirectoryTypeNotes) { // We need to edit the notes thing...
			NotesViewController *nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
			
			// If we got a new view controller, push it .
			if (nextViewController) {
				nextViewController.legislator = self.legislator;
				nextViewController.backView = tableView;
				[self.navigationController pushViewController:nextViewController animated:YES];
				[nextViewController release];
			}
			
		}
		else if (cellInfo.entryType == DirectoryTypeCommittee) {
			CommitteeDetailViewController *subDetailController = [[CommitteeDetailViewController alloc] initWithNibName:@"CommitteeDetailViewController" bundle:nil];
			subDetailController.committee = [[[self.legislator sortedCommitteePositions] objectAtIndex:row] committee];
			// push the detail view controller onto the navigation stack to display it
			[self.navigationController pushViewController:subDetailController animated:YES];
			[subDetailController release];
		}
		else if (cellInfo.entryType == DirectoryTypeOfficeMap || cellInfo.entryType == DirectoryTypeChamberMap) {
			[self pushMapViewWithURL:[cellInfo generateURL:self.legislator]];
		}
		else if (cellInfo.entryType > kDirectoryTypeIsURLHandler &&
				 cellInfo.entryType < kDirectoryTypeIsExternalHandler) {	// handle the URL ourselves in a webView
			[self showWebViewWithURL:[cellInfo generateURL:self.legislator]];
		}
		else if (cellInfo.entryType > kDirectoryTypeIsExternalHandler)		// tell the device to open the url externally
		{
			NSURL *myURL = [cellInfo generateURL:self.legislator];
			// do the URL
			
			BOOL isPhone = ([UtilityMethods canMakePhoneCalls]);
			if ((cellInfo.entryType == DirectoryTypePhone) && (!isPhone)) {
				debug_NSLog(@"Tried to make a phonecall, but this isn't a phone: %@", myURL.description);
				[UtilityMethods alertNotAPhone];
				return;
			}
			
			// Switch to the appropriate application for this url...
			if (cellInfo.entryType == DirectoryTypeMap)
				[UtilityMethods openURLWithTrepidation:myURL];
			else
				[UtilityMethods openURLWithoutTrepidation:myURL];
		}
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height = 44.0f;
	NSInteger row = [indexPath row];
	NSInteger section = [indexPath section];
	
	DirectoryDetailInfo *cellInfo = nil;
	NSMutableArray *entryArray = [self.sectionArray objectAtIndex:section];
	if (entryArray)
		cellInfo = [entryArray objectAtIndex:row];
	
	if (cellInfo == nil) {
		NSLog(@"LegislatorDetailViewController:heightForRow: error finding table entry for section:%d row:%d", section, row);
		return height;
	}
	
	if (cellInfo.entryValue.length <= 0) {
		height = 0.0f;
	}
	else if ([cellInfo.entryName rangeOfString:@"Address"].length > 0) { // We found "Address" in the string.
		height = 98.0f;
	}
	return height;
}


- (void) pushMapViewWithURL:(NSURL *)url {
	MapsDetailViewController *detailController = [[MapsDetailViewController alloc] initWithNibName:@"MapsDetailViewController" bundle:nil];
	detailController.mapURL = url;
	detailController.navigationItem.title = @"Maps";
	// push the detail view controller onto the navigation stack to display it
	[[self navigationController] pushViewController:detailController animated:YES];
	[detailController release];
}

- (void) showWebViewWithURL:(NSURL *)url {
	if ([url isFileURL])	// it's a maps table, use our own webview.
		[self pushMapViewWithURL:url];
	else
		if ([UtilityMethods canReachHostWithURL:url]) { // do we have a good URL/connection?
			MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:url];
			[mbc display:self];
		}
}	


#pragma mark -
#pragma mark Plot construction methods

- (void)constructScatterPlot
{
	// Create graph from theme
    graph = [[CPXYGraph alloc] initWithFrame:CGRectZero];
	CPTheme *theme = [CPTheme themeNamed:kCPStocksTheme];
	//CPTheme *theme = [CPTheme themeNamed:kCPSlateTheme];
    [graph applyTheme:theme];
    scatterPlotView.hostedLayer = graph;
	
    graph.paddingLeft = 10.0;
	graph.paddingTop = 10.0;
	graph.paddingRight = 10.0;
	graph.paddingBottom = 10.0;
    
    // Setup plot space
    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.0) length:CPDecimalFromFloat(2.0)];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.0) length:CPDecimalFromFloat(3.0)];
	
    // Axes
	CPXYAxisSet *axisSet = (CPXYAxisSet *)graph.axisSet;
    CPXYAxis *x = axisSet.xAxis;
    x.majorIntervalLength = CPDecimalFromString(@"0.5");
    x.orthogonalCoordinateDecimal = CPDecimalFromString(@"2");
    x.minorTicksPerInterval = 2;
 	NSArray *exclusionRanges = [NSArray arrayWithObjects:
								[CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.99) length:CPDecimalFromFloat(0.02)], 
								[CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.99) length:CPDecimalFromFloat(0.02)],
								[CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(2.99) length:CPDecimalFromFloat(0.02)],
								nil];
	x.labelExclusionRanges = exclusionRanges;
	
    CPXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength = CPDecimalFromString(@"0.5");
    y.minorTicksPerInterval = 5;
    y.orthogonalCoordinateDecimal = CPDecimalFromString(@"2");
	exclusionRanges = [NSArray arrayWithObjects:
					   [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.99) length:CPDecimalFromFloat(0.02)], 
					   [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.99) length:CPDecimalFromFloat(0.02)],
					   [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(3.99) length:CPDecimalFromFloat(0.02)],
					   nil];
	y.labelExclusionRanges = exclusionRanges;
	
	// Create a blue plot area
	CPScatterPlot *boundLinePlot = [[[CPScatterPlot alloc] init] autorelease];
    boundLinePlot.identifier = @"Blue Plot";
	boundLinePlot.dataLineStyle.miterLimit = 1.0f;
	boundLinePlot.dataLineStyle.lineWidth = 3.0f;
	boundLinePlot.dataLineStyle.lineColor = [CPColor blueColor];
    boundLinePlot.dataSource = self;
	[graph addPlot:boundLinePlot];
	
	// Do a blue gradient
	CPColor *areaColor1 = [CPColor colorWithComponentRed:0.3 green:0.3 blue:1.0 alpha:0.8];
    CPGradient *areaGradient1 = [CPGradient gradientWithBeginningColor:areaColor1 endingColor:[CPColor clearColor]];
    areaGradient1.angle = -90.0f;
    CPFill *areaGradientFill = [CPFill fillWithGradient:areaGradient1];
    boundLinePlot.areaFill = areaGradientFill;
    boundLinePlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];    
	
	// Add plot symbols
	CPLineStyle *symbolLineStyle = [CPLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPColor blackColor];
	CPPlotSymbol *plotSymbol = [CPPlotSymbol ellipsePlotSymbol];
	plotSymbol.fill = [CPFill fillWithColor:[CPColor blueColor]];
	plotSymbol.lineStyle = symbolLineStyle;
    plotSymbol.size = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
	
    // Create a green plot area
	CPScatterPlot *dataSourceLinePlot = [[[CPScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Green Plot";
	dataSourceLinePlot.dataLineStyle.lineWidth = 3.f;
    dataSourceLinePlot.dataLineStyle.lineColor = [CPColor greenColor];
	dataSourceLinePlot.dataLineStyle.dashPattern = [NSArray arrayWithObjects:[NSNumber numberWithFloat:5.0f], [NSNumber numberWithFloat:5.0f], nil];
    dataSourceLinePlot.dataSource = self;
	
	// Put an area gradient under the plot above
    CPColor *areaColor = [CPColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
    CPGradient *areaGradient = [CPGradient gradientWithBeginningColor:areaColor endingColor:[CPColor clearColor]];
    areaGradient.angle = -90.0f;
    areaGradientFill = [CPFill fillWithGradient:areaGradient];
    dataSourceLinePlot.areaFill = areaGradientFill;
    dataSourceLinePlot.areaBaseValue = CPDecimalFromString(@"1.75");
	
	// Animate in the new plot, as an example
	dataSourceLinePlot.opacity = 0.0f;
    [graph addPlot:dataSourceLinePlot];
	
	CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.duration = 1.0f;
	fadeInAnimation.removedOnCompletion = NO;
	fadeInAnimation.fillMode = kCAFillModeForwards;
	fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
	[dataSourceLinePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];
	
    // Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
	NSUInteger i;
	for ( i = 0; i < 60; i++ ) {
		id x = [NSNumber numberWithFloat:1+i*0.05];
		id y = [NSNumber numberWithFloat:1.2*rand()/(float)RAND_MAX + 1.2];
		[contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
	}
	self.dataForPlot = contentArray;
	
}

/*
- (void)constructBarChart
{
    // Create barChart from theme
    barChart = [[CPXYGraph alloc] initWithFrame:CGRectZero];
	CPTheme *theme = [CPTheme themeNamed:kCPDarkGradientTheme];
    [barChart applyTheme:theme];
    barChartView.hostedLayer = barChart;
    barChart.plotAreaFrame.masksToBorder = NO;
	
    barChart.paddingLeft = 70.0;
	barChart.paddingTop = 20.0;
	barChart.paddingRight = 20.0;
	barChart.paddingBottom = 80.0;
	
	// Add plot space for horizontal bar charts
    CPXYPlotSpace *plotSpace = (CPXYPlotSpace *)barChart.defaultPlotSpace;
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0f) length:CPDecimalFromFloat(300.0f)];
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0f) length:CPDecimalFromFloat(16.0f)];
    
	
	CPXYAxisSet *axisSet = (CPXYAxisSet *)barChart.axisSet;
    CPXYAxis *x = axisSet.xAxis;
    x.axisLineStyle = nil;
    x.majorTickLineStyle = nil;
    x.minorTickLineStyle = nil;
    x.majorIntervalLength = CPDecimalFromString(@"5");
    x.orthogonalCoordinateDecimal = CPDecimalFromString(@"0");
	x.title = @"X Axis";
    x.titleLocation = CPDecimalFromFloat(7.5f);
	x.titleOffset = 55.0f;
	
	// Define some custom labels for the data elements
	x.labelRotation = M_PI/4;
	x.labelingPolicy = CPAxisLabelingPolicyNone;
	NSArray *customTickLocations = [NSArray arrayWithObjects:[NSDecimalNumber numberWithInt:1], [NSDecimalNumber numberWithInt:5], [NSDecimalNumber numberWithInt:10], [NSDecimalNumber numberWithInt:15], nil];
	NSArray *xAxisLabels = [NSArray arrayWithObjects:@"Label A", @"Label B", @"Label C", @"Label D", @"Label E", nil];
	NSUInteger labelLocation = 0;
	NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:[xAxisLabels count]];
	for (NSNumber *tickLocation in customTickLocations) {
		CPAxisLabel *newLabel = [[CPAxisLabel alloc] initWithText: [xAxisLabels objectAtIndex:labelLocation++] textStyle:x.labelTextStyle];
		newLabel.tickLocation = [tickLocation decimalValue];
		newLabel.offset = x.labelOffset + x.majorTickLength;
		newLabel.rotation = M_PI/4;
		[customLabels addObject:newLabel];
		[newLabel release];
	}
	
	x.axisLabels =  [NSSet setWithArray:customLabels];
	
	CPXYAxis *y = axisSet.yAxis;
    y.axisLineStyle = nil;
    y.majorTickLineStyle = nil;
    y.minorTickLineStyle = nil;
    y.majorIntervalLength = CPDecimalFromString(@"50");
    y.orthogonalCoordinateDecimal = CPDecimalFromString(@"0");
	y.title = @"Y Axis";
	y.titleOffset = 45.0f;
    y.titleLocation = CPDecimalFromFloat(150.0f);
	
    // First bar plot
    CPBarPlot *barPlot = [CPBarPlot tubularBarPlotWithColor:[CPColor darkGrayColor] horizontalBars:NO];
    barPlot.baseValue = CPDecimalFromString(@"0");
    barPlot.dataSource = self;
    barPlot.barOffset = -0.25f;
    barPlot.identifier = @"Bar Plot 1";
    [barChart addPlot:barPlot toPlotSpace:plotSpace];
    
    // Second bar plot
    barPlot = [CPBarPlot tubularBarPlotWithColor:[CPColor blueColor] horizontalBars:NO];
    barPlot.dataSource = self;
    barPlot.baseValue = CPDecimalFromString(@"0");
    barPlot.barOffset = 0.25f;
    barPlot.cornerRadius = 2.0f;
    barPlot.identifier = @"Bar Plot 2";
    [barChart addPlot:barPlot toPlotSpace:plotSpace];
}

- (void)constructPieChart
{
	// Create pieChart from theme
    pieChart = [[CPXYGraph alloc] initWithFrame:CGRectZero];
	CPTheme *theme = [CPTheme themeNamed:kCPDarkGradientTheme];
    [pieChart applyTheme:theme];
    pieChartView.hostedLayer = pieChart;
    pieChart.plotAreaFrame.masksToBorder = NO;
	
    pieChart.paddingLeft = 20.0;
	pieChart.paddingTop = 20.0;
	pieChart.paddingRight = 20.0;
	pieChart.paddingBottom = 20.0;
	
	pieChart.axisSet = nil;
	
    // Add pie chart
    CPPieChart *piePlot = [[CPPieChart alloc] init];
    piePlot.dataSource = self;
    piePlot.pieRadius = 130.0;
    piePlot.identifier = @"Pie Chart 1";
	piePlot.startAngle = M_PI_4;
	piePlot.sliceDirection = CPPieDirectionCounterClockwise;
    [pieChart addPlot:piePlot];
    [piePlot release];
	
	// Add some initial data
	NSMutableArray *contentArray = [NSMutableArray arrayWithObjects:[NSNumber numberWithDouble:20.0], [NSNumber numberWithDouble:30.0], [NSNumber numberWithDouble:60.0], nil];
	self.dataForChart = contentArray;	
}
*/

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot 
{
/*
	if ([plot isKindOfClass:[CPPieChart class]])
		return [self.dataForChart count];
	else if ([plot isKindOfClass:[CPBarPlot class]])
		return 16;
	else
*/
		return [dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index 
{
    NSDecimalNumber *num = nil;
/*
	if ( [plot isKindOfClass:[CPPieChart class]] ) {
		if ( index >= [self.dataForChart count] ) return nil;
		
		if ( fieldEnum == CPPieChartFieldSliceWidth ) {
			return [self.dataForChart objectAtIndex:index];
		}
		else {
			return [NSNumber numberWithInt:index];
		}
	}
    else if ( [plot isKindOfClass:[CPBarPlot class]] ) {
		switch ( fieldEnum ) {
			case CPBarPlotFieldBarLocation:
				num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:index];
				break;
			case CPBarPlotFieldBarLength:
				num = (NSDecimalNumber *)[NSDecimalNumber numberWithUnsignedInteger:(index+1)*(index+1)];
				if ( [plot.identifier isEqual:@"Bar Plot 2"] ) 
					num = [num decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithString:@"10"]];
				break;
		}
    }
	else
*/
	{
		//NSLog(@"Plot: %@, fieldEnum: %d, recordIndex: %d", plot, fieldEnum, index);
		num = [[dataForPlot objectAtIndex:index] valueForKey:(fieldEnum == CPScatterPlotFieldX ? @"x" : @"y")];
		// Green plot gets shifted above the blue
		if ([(NSString *)plot.identifier isEqualToString:@"Green Plot"])
		{
			if ( fieldEnum == CPScatterPlotFieldY ) 
				num = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:[num doubleValue] + 1.0];
		}
	}
	
    return num;
}

-(CPFill *) barFillForBarPlot:(CPBarPlot *)barPlot recordIndex:(NSNumber *)index; 
{
	return nil;
}


@end

