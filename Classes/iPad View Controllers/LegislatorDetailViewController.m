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
#import "DetailTableViewController.h"
@interface LegislatorDetailViewController (Private)
@property (nonatomic, retain) UIPopoverController *popoverController;

- (void) pushMapViewWithURL:(NSURL *)url;
- (void) pushInternalBrowserWithURL:(NSURL *)url;
- (void) showWebViewWithURL:(NSURL *)url;
	
@end


@implementation LegislatorDetailViewController

@synthesize popoverController;//, m_popButton;

@synthesize legislator;
@synthesize leg_photoView, leg_titleLab, leg_partyLab, leg_districtLab, leg_tenureLab, leg_nameLab;
@synthesize indivSlider, partySlider, allSlider;
@synthesize indivPHolder, partyPHolder, allPHolder;
@synthesize indivView, partyView, allView;

@synthesize sectionArray;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

	//self.tableView.delegate = self;
	//self.tableView.dataSource = self;
	
    // Uncomment the following line to preserve selection between presentations.
     self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	//self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	//self.m_popButton.action = @selector(showMasterInPopover:);


}

- (void)setupHeader {
	self.leg_nameLab.text = [NSString stringWithFormat:@"%@ %@",  [self.legislator legTypeShortName], 
					 [self.legislator legProperName]];
	self.navigationItem.title = self.leg_nameLab.text;

	self.leg_photoView.image = [UtilityMethods poorMansImageNamed:self.legislator.photo_name];
	self.leg_titleLab.text = self.legislator.legtype_name;
	self.leg_partyLab.text = [self.legislator party_name];
	self.leg_districtLab.text = [NSString stringWithFormat:@"District %@", self.legislator.district];
	self.leg_tenureLab.text = [self.legislator tenureString];
	
	if (self.indivSlider == nil) {
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
	}
	if (self.indivSlider) {
		self.indivSlider.sliderValue = self.legislator.partisan_index.floatValue;
	}	
}

- (void)setLegislator:(LegislatorObj *)newLegislator {
	[self.indivView removeFromSuperview];

	if (newLegislator) {
		if (legislator) [legislator release], legislator = nil;
		legislator = [newLegislator retain];
	}
	[self setupHeader];
	
	if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }        
	
	[self createSectionList];
	
	[self.tableView reloadData];
	[self.view setNeedsDisplay];
	
	NSLog(@"Delegate: %@", self.tableView.delegate);
	//NSLog(@"Delegate: %@", self.tableView.delegate);
	
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	// we don't have a legislator selected and yet we're appearing in portrait view ... got to have something here !!! 
	if (self.legislator == nil && ![UtilityMethods isLandscapeOrientation])  {
		[self.view addSubview:self.indivView];
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
		[self.indivView removeFromSuperview];
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

/*
- (IBAction)showMasterInPopover:(id)sender {
	[self.splitViewController showMasterInPopover:sender];
}
*/

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController 
		  withBarButtonItem:(UIBarButtonItem*)barButtonItem 
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
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}



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
	//self.toolbar = nil;
	
	self.indivSlider = self.partySlider = self.allSlider = nil;
	self.indivPHolder = self.partyPHolder = self.allPHolder = nil;
	self.indivView = self.partyView = self.allView = nil;
	
	self.legislator = nil;
	
	self.leg_photoView = nil;
	self.leg_partyLab = self.leg_districtLab = self.leg_tenureLab = self.leg_nameLab = nil;

}


- (void)dealloc {
    [super dealloc];
}


#pragma mark -
#pragma mark Table view data source

- (void) createSectionList {
	NSInteger numberOfSections = 3 + [self.legislator numberOfDistrictOffices];
	
	NSArray *keys = nil;
	NSArray *objects = nil;
	NSString *tempString = nil;
	NSNumber *boolYES = [NSNumber numberWithBool:YES];
	NSNumber *boolNO = [NSNumber numberWithBool:NO];
	NSNumber *boolIsPhone = [NSNumber numberWithBool:[UtilityMethods canMakePhoneCalls]];
	
	
	sectionArray = [[[NSMutableArray alloc] initWithCapacity:numberOfSections] retain];
	//for (int i = 0; i < numberOfSections; i++) [sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
	
	// this holds each section, in another MutableArray
	// then that array holds each entry in the section, wich is made up of ...
	// an NSObject, created from the contents of a temporary dictionary....
	
	keys = [NSArray arrayWithObjects:		@"entryName", @"entryValue", @"isClickable", @"entryType", nil];
	
	/*	Section 0: Personal Information */		
	NSInteger sectionIndex = 0;
	[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
	
	objects = [NSArray arrayWithObjects:	@"Name", [self.legislator fullName], 
			   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
	[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	
	objects = [NSArray arrayWithObjects:	@"Website", self.legislator.website, 
			   boolYES, [NSNumber numberWithInteger:DirectoryTypeWeb], nil];
	[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	
	objects = [NSArray arrayWithObjects:	@"Bio", self.legislator.bio_url, 
			   boolYES, [NSNumber numberWithInteger:DirectoryTypeWeb], nil];
	[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	
	objects = [NSArray arrayWithObjects:	@"Email", self.legislator.email, 
			   boolYES, [NSNumber numberWithInteger:DirectoryTypeMail], nil];
	[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	
	if (self.legislator.twitter.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Twitter", [NSString stringWithFormat:@"@%@", self.legislator.twitter], 
				   boolYES, [NSNumber numberWithInteger:DirectoryTypeTwitter], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	}
	if (![UtilityMethods isIPadDevice]) {
		if (self.legislator.partisan_index.floatValue != 0.0f) {
			objects = [NSArray arrayWithObjects:	@"Index",  self.legislator.partisan_index.stringValue,
					   boolNO, [NSNumber numberWithInteger:DirectoryTypeIndex], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
			
			objects = [NSArray arrayWithObjects:	@"",  @"About the Roll Call Index", 
					   boolYES, [NSNumber numberWithInteger:DirectoryTypeIndexAbout], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		}
	}	
	if (self.legislator.notes.length > 0) {
		tempString = self.legislator.notes;
	}
	else
		tempString = kStaticNotes;
	
	objects = [NSArray arrayWithObjects:	@"Notes",  tempString, 
			   boolYES, [NSNumber numberWithInteger:DirectoryTypeNotes], nil];
	[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	
	
	
	/* after that section's done... DO COMMITTEES */
	sectionIndex++;
	[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
	
	for (CommitteePositionObj *position in [self.legislator sortedCommitteePositions]) {
		objects = [NSArray arrayWithObjects:[position positionString],  [position.committee committeeName], 
				   boolYES, [NSNumber numberWithInteger:DirectoryTypeCommittee], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	}
	
	/* after that section's done... */
	sectionIndex++;
	[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
	
	/*	Section 1: Capitol Office */		
	
	if (legislator.staff.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Staff", self.legislator.staff, 
				   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	}
	if (self.legislator.cap_office.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Office",  self.legislator.cap_office, 
				   boolYES, [NSNumber numberWithInteger:DirectoryTypeOfficeMap], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	} 
	if (legislator.chamber_desk.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Desk #",  self.legislator.chamber_desk, 
				   boolYES, [NSNumber numberWithInteger:DirectoryTypeChamberMap], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	}
	if (legislator.cap_phone.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Phone",  self.legislator.cap_phone, 
				   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	} 
	if (legislator.cap_fax.length > 0) {
		objects = [NSArray arrayWithObjects:	@"Fax",  self.legislator.cap_fax, 
				   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	}
	if (legislator.cap_phone2.length > 0) {
		tempString = (self.legislator.cap_phone2_name.length > 0) ? self.legislator.cap_phone2_name : @"Phone #2";
		
		objects = [NSArray arrayWithObjects:	tempString,  self.legislator.cap_phone2, 
				   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
		[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
	} 
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 1) {
		sectionIndex++;
		[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
		
		/*	Section 2: District 1 */		
		
		if (legislator.dist1_phone.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Phone",  self.legislator.dist1_phone, 
					   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
		if (legislator.dist1_fax.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Fax",  self.legislator.dist1_fax, 
					   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		}
		if (legislator.dist1_street.length > 0) {
			tempString = [self.legislator.dist1_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"];
			tempString = [NSString stringWithFormat:@"%@\n%@, TX\n%@", 
						  tempString, self.legislator.dist1_city, self.legislator.dist1_zip];
			
			objects = [NSArray arrayWithObjects:	@"Address", tempString, 
					   boolYES, [NSNumber numberWithInteger:DirectoryTypeMap], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 2) {
		sectionIndex++;
		[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
		/*	Section 3: District 2 */		
		
		if (legislator.dist2_phone.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Phone",  self.legislator.dist2_phone, 
					   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
		if (legislator.dist2_fax.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Fax",  self.legislator.dist2_fax, 
					   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		}
		if (legislator.dist2_street.length > 0) {
			tempString = [self.legislator.dist2_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"];
			tempString = [NSString stringWithFormat:@"%@\n%@, TX\n%@", 
						  tempString, self.legislator.dist2_city, self.legislator.dist2_zip];
			
			objects = [NSArray arrayWithObjects:	@"Address", tempString, 
					   boolYES, [NSNumber numberWithInteger:DirectoryTypeMap], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 3) {
		sectionIndex++;
		[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
		/*	Section 4: District 3 */		
		
		if (legislator.dist3_phone1.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Phone",  self.legislator.dist3_phone1, 
					   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
		if (legislator.dist3_fax.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Fax",  self.legislator.dist3_fax, 
					   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		}
		if (legislator.dist3_street.length > 0) {
			tempString = [self.legislator.dist3_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"];
			tempString = [NSString stringWithFormat:@"%@\n%@, TX\n%@", 
						  tempString, self.legislator.dist3_city, self.legislator.dist3_zip];
			
			objects = [NSArray arrayWithObjects:	@"Address", tempString, 
					   boolYES, [NSNumber numberWithInteger:DirectoryTypeMap], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
	}
	
	/* after that section's done... */
	
	if ([legislator numberOfDistrictOffices] >= 4) {
		sectionIndex++;
		[sectionArray addObject:[[[NSMutableArray alloc] init] retain]];
		/*	Section 5: District 4 */		
		
		if (legislator.dist4_phone1.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Phone",  self.legislator.dist4_phone1, 
					   boolIsPhone, [NSNumber numberWithInteger:DirectoryTypePhone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
		if (legislator.dist4_fax.length > 0) {
			objects = [NSArray arrayWithObjects:	@"Fax",  self.legislator.dist4_fax, 
					   boolNO, [NSNumber numberWithInteger:DirectoryTypeNone], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		}
		if (legislator.dist4_street.length > 0) {
			tempString = [self.legislator.dist4_street stringByReplacingOccurrencesOfString:@", " withString:@"\n"];
			tempString = [NSString stringWithFormat:@"%@\n%@, TX\n%@", 
						  tempString, self.legislator.dist4_city, self.legislator.dist4_zip];
			
			objects = [NSArray arrayWithObjects:	@"Address", tempString, 
					   boolYES, [NSNumber numberWithInteger:DirectoryTypeMap], nil];
			[self createEntryInSection:sectionIndex WithKeys:keys andObjects:objects];
		} 
	}
	
}	

- (void) createEntryInSection:(NSInteger)sectionIndex WithKeys:(NSArray *)keys andObjects:(NSArray *)objects {
	NSMutableDictionary *aDictionary = [NSMutableDictionary dictionaryWithObjects:objects forKeys:keys];
	
	DirectoryDetailInfo *cellInfo = [[DirectoryDetailInfo alloc] initWithDictionary:aDictionary];
	[[sectionArray objectAtIndex:sectionIndex] addObject:cellInfo];
	// guess we don't need to release the dictionary...
	[cellInfo release];
}

- (void) standardTextCell:(UITableViewCell *)cell withInfo:(DirectoryDetailInfo *)cellInfo {
	if (cellInfo.entryValue.length > 0)	cell.detailTextLabel.text = cellInfo.entryValue;
	if (cellInfo.entryName.length > 0)	cell.textLabel.text = cellInfo.entryName;
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
	
	DirectoryDetailInfo *cellInfo = [[sectionArray objectAtIndex:section] objectAtIndex:row];
	
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
	
	NSString * tempString;
	switch(cellInfo.entryType) {
		case DirectoryTypeNotes:		// Since our notes data can change, we must tend to the cached info ...
			if (self.legislator.notes.length > 0) {
				tempString = self.legislator.notes;
				cell.detailTextLabel.textColor = [UIColor blackColor];
			}
			else {
				tempString = kStaticNotes;
				cell.detailTextLabel.textColor = [UIColor grayColor];
			}
			cellInfo.entryValue = tempString;
			[self standardTextCell:cell withInfo:cellInfo];
			break;
			
		case DirectoryTypeIndexAbout:  // About the Partisanship Index...
			if (![UtilityMethods isIPadDevice]) {
				cell.detailTextLabel.textColor = [UIColor colorWithRed:56.0/256.0 green:84/256.0 blue:135/256.0 alpha:1.0];
				cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14];
				cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
				[self standardTextCell:cell withInfo:cellInfo];
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
			[self standardTextCell:cell withInfo:cellInfo];
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
			[self standardTextCell:cell withInfo:cellInfo];
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
	
	DirectoryDetailInfo *cellInfo = [[sectionArray objectAtIndex:section] objectAtIndex:row];
	
	if (cellInfo.isClickable) {
		if (cellInfo.entryType == DirectoryTypeIndexAbout) {
			TexLegeAppDelegate *appDelegate = (TexLegeAppDelegate *)[[UIApplication sharedApplication] delegate];
			if (appDelegate != nil) [appDelegate showVoteInfoDialog:self];
		}
		else if (cellInfo.entryType == DirectoryTypeNotes) { // We need to edit the notes thing...
			UIViewController *nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
			((NotesViewController *)nextViewController).legislator = self.legislator;
			((NotesViewController *)nextViewController).backView = tableView;
			
			// If we got a new view controller, push it .
			if (nextViewController) {
				[self.navigationController pushViewController:nextViewController animated:YES];
				[nextViewController release];
			}
			
		}
		else if (cellInfo.entryType == DirectoryTypeCommittee) {
			CommitteeDetailViewController *subDetailController = [[CommitteeDetailViewController alloc] init];
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
	
	//DirectoryDetailInfo *cellInfo = [[DirectoryDetailInfo alloc] init];
	//[self infoForRow:cellInfo atIndexPath:indexPath];
	
	DirectoryDetailInfo *cellInfo = [[sectionArray objectAtIndex:section] objectAtIndex:row];
	
	if (cellInfo.entryValue.length <= 0) {
		height = 0.0f;
	}
	else if ([cellInfo.entryName rangeOfString:@"Address"].length > 0) { // We found "Address" in the string.
		height = 98.0f;
	}
	return height;
}


- (void) pushMapViewWithURL:(NSURL *)url {
	DetailTableViewController *detailController = [[DetailTableViewController alloc] init];
	detailController.webViewURL = url;
	[[self navigationController] pushViewController:detailController animated:YES];
	
	[detailController release];
	
}

- (void) pushInternalBrowserWithURL:(NSURL *)url {
	if ([UtilityMethods canReachHostWithURL:url]) { // do we have a good URL/connection?
		MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:url];
		[mbc display:self];
	}
}

- (void) showWebViewWithURL:(NSURL *)url {
	if ([url isFileURL]) {// we don't implicitely "push" this one, since we might be a maps table.
		[self pushMapViewWithURL:url];
	}
	else
		[self pushInternalBrowserWithURL:url];
}	

@end

