//
//  LegislatorDetailViewController.m
//  TexLege
//
//  Created by Gregory Combs on 6/28/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import "TableDataSourceProtocol.h"
#import "LegislatorDetailViewController.h"
#import "LegislatorDetailDataSource.h"
#import "LegislatorContributionsViewController.h"

#import "LegislatorMasterViewController.h"
#import "LegislatorObj+RestKit.h"
#import "DistrictOfficeObj+MapKit.h"
#import "DistrictMapObj+RestKit.h"
#import "DistrictMapObj+MapKit.h"
#import "CommitteeObj.h"
#import "CommitteePositionObj.h"
#import "WnomObj+RestKit.h"
#import "TexLegeCoreDataUtils.h"
#import "UtilityMethods.h"
#import "TableDataSourceProtocol.h"
#import "TableCellDataObject.h"
#import "NotesViewController.h"
#import "TexLegeAppDelegate.h"

#import "BillSearchDataSource.h"
#import "BillsListDetailViewController.h"
#import "CommitteeDetailViewController.h"
#import "DistrictOfficeMasterViewController.h"

#import "MapMiniDetailViewController.h"
#import "MiniBrowserController.h"
#import "CapitolMapsDetailViewController.h"

#import "PartisanIndexStats.h"
#import "UIImage+ResolutionIndependent.h"

#import "TexLegeEmailComposer.h"
#import "PartisanScaleView.h"
#import "LocalyticsSession.h"

#import "VotingRecordDataSource.h"

@interface LegislatorDetailViewController (Private)
- (void) setupHeader;
@end


@implementation LegislatorDetailViewController
@synthesize dataObjectID;
@synthesize dataSource;
@synthesize headerView, miniBackgroundView;

@synthesize leg_indexTitleLab, leg_rankLab, leg_chamberPartyLab, leg_chamberLab, leg_reelection;
@synthesize leg_photoView, leg_partyLab, leg_districtLab, leg_tenureLab, leg_nameLab, freshmanPlotLab;
@synthesize indivSlider, partySlider, allSlider;
@synthesize notesPopover, masterPopover;
@synthesize newChartView, votingDataSource;

#pragma mark -
#pragma mark View lifecycle

- (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"LegislatorDetailViewController~ipad";
	else
		return @"LegislatorDetailViewController~iphone";
}

- (void)viewDidLoad {
    [super viewDidLoad];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_LEGISLATOROBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_STAFFEROBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_DISTRICTOFFICEOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_DISTRICTMAPOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_COMMITTEEPOSITIONOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:@"RESTKIT_LOADED_WNOMOBJ" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetTableData:) name:kPartisanIndexNotifyLoaded object:nil];
	
	UIImage *sealImage = [UIImage imageNamed:@"seal.png"];
	UIColor *sealColor = [[UIColor colorWithPatternImage:sealImage] colorWithAlphaComponent:0.5f];	
	self.miniBackgroundView.backgroundColor = sealColor;
	//self.headerView.backgroundColor = sealColor;
	
	self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.clearsSelectionOnViewWillAppear = NO;
				
	VotingRecordDataSource *votingDS = [[VotingRecordDataSource alloc] init];
	[votingDS prepareVotingRecordView:self.newChartView];
	self.votingDataSource = votingDS;
	[votingDS release];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.votingDataSource = nil;
	[super viewDidUnload];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
	UINavigationController *nav = [self navigationController];
	if (nav && [nav.viewControllers count]>2)
		[nav popToRootViewControllerAnimated:YES];
		
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
	self.indivSlider = nil;
	self.partySlider = nil;
	self.allSlider = nil;
	self.dataSource = nil;
	self.headerView = nil;
	self.leg_photoView = nil;
	self.leg_reelection = nil;
	self.miniBackgroundView = nil;
	self.leg_partyLab = self.leg_districtLab = self.leg_tenureLab = self.leg_nameLab = self.freshmanPlotLab = nil;
	self.notesPopover = nil;
	self.masterPopover = nil;
	self.dataObjectID = nil;
	self.newChartView = nil;
	self.votingDataSource = nil;

	[super dealloc];
}

- (id)dataObject {
	return self.legislator;
}

- (void)setDataObject:(id)newObj {
	[self setLegislator:newObj];
}

- (NSString *)chamberPartyAbbrev {
	LegislatorObj *member = self.legislator;
	NSString *partyName = nil;
	if ([member.party_id integerValue] == DEMOCRAT) // Democrat
		partyName = @"Dems";
	else if ([member.party_id integerValue] == REPUBLICAN) // Republican
		partyName = @"Repubs";
	else // don't know the party?
		partyName = @"Indeps";
	
	return [NSString stringWithFormat:@"%@ %@", [member chamberName], partyName];
}

- (NSString *) partisanRankStringForLegislator {
	LegislatorObj *member = self.legislator;
	if (member.tenure.integerValue == 0)
		return @"";

	NSArray *legislators = [TexLegeCoreDataUtils allLegislatorsSortedByPartisanshipFromChamber:[member.legtype integerValue] 
																					andPartyID:[member.party_id integerValue]];
	if (legislators) {
		NSInteger rankIndex = [legislators indexOfObject:member] + 1;
		NSInteger count = [legislators count];
		NSString *partyShortName = [member.party_id integerValue] == DEMOCRAT ? @"Dems" : @"Repubs";
		
		NSString *ordinalRank = [UtilityMethods ordinalNumberFormat:rankIndex];
		return [NSString stringWithFormat:@"%@ most partisan (out of %d %@)", ordinalRank, count, partyShortName];	
	}
	else {
		return @"";
	}
}

- (void)setupHeader {
	LegislatorObj *member = self.legislator;
	
	NSString *legName = [NSString stringWithFormat:@"%@ %@",  [member legTypeShortName], [member legProperName]];
	self.leg_nameLab.text = legName;
	self.navigationItem.title = legName;

	//[[ImageCache sharedImageCache] loadImageView:self.leg_photoView fromPath:[UIImage highResImagePathWithPath:member.photo_name]];
	self.leg_photoView.image = [UIImage imageNamed:[UIImage highResImagePathWithPath:member.photo_name]];
	self.leg_partyLab.text = [member party_name];
	self.leg_districtLab.text = [NSString stringWithFormat:@"District %@", member.district];
	self.leg_tenureLab.text = [member tenureString];
	if (member.nextElection) {
		
		self.leg_reelection.text = [NSString stringWithFormat:@"Reelection: %@", member.nextElection];
	}
	
	PartisanIndexStats *indexStats = [PartisanIndexStats sharedPartisanIndexStats];

	if (self.leg_indexTitleLab)
		self.leg_indexTitleLab.text = [NSString stringWithFormat:@"%@ %@", 
									   [member legTypeShortName], [member lastname]];

	if (self.leg_rankLab)
		self.leg_rankLab.text = [self partisanRankStringForLegislator];
	
	if (self.leg_chamberPartyLab) {
		self.leg_chamberPartyLab.text = [self chamberPartyAbbrev];
		self.leg_chamberLab.text = [[member chamberName] stringByAppendingString:@" Avg."];				
	}
	
	CGFloat minSlider = [indexStats minPartisanIndexUsingChamber:[member.legtype integerValue]];
	CGFloat maxSlider = [indexStats maxPartisanIndexUsingChamber:[member.legtype integerValue]];
	
	if (self.indivSlider) {
		self.indivSlider.sliderMin = minSlider;
		self.indivSlider.sliderMax = maxSlider;
		self.indivSlider.sliderValue = member.latestWnomFloat;
	}	
	if (self.partySlider) {
		self.partySlider.sliderMin = minSlider;
		self.partySlider.sliderMax = maxSlider;
		self.partySlider.sliderValue = [indexStats partyPartisanIndexUsingChamber:[member.legtype integerValue] andPartyID:[member.party_id integerValue]];
	}	
	if (self.allSlider) {
		self.allSlider.sliderMin = minSlider;
		self.allSlider.sliderMax = maxSlider;
		self.allSlider.sliderValue = [indexStats overallPartisanIndexUsingChamber:[member.legtype integerValue]];
	}	
	
	BOOL hasScores = !IsEmpty(member.wnomScores);
	self.freshmanPlotLab.hidden = hasScores;
	self.newChartView.hidden = !hasScores;

}


- (LegislatorDetailDataSource *)dataSource {
	LegislatorObj *member = self.legislator;
	if (!dataSource && member) {
		dataSource = [[LegislatorDetailDataSource alloc] initWithLegislator:member];
	}
	return dataSource;
}

- (void)setDataSource:(LegislatorDetailDataSource *)newObj {	
	if (newObj == dataSource)
		return;
	if (dataSource)
		[dataSource release], dataSource = nil;
	if (newObj)
		dataSource = [newObj retain];
}


- (LegislatorObj *)legislator {
	LegislatorObj *anObject = nil;
	if (self.dataObjectID) {
		@try {
			anObject = [LegislatorObj objectWithPrimaryKeyValue:self.dataObjectID];
		}
		@catch (NSException * e) {
		}
	}
	return anObject;
}

- (void)setLegislator:(LegislatorObj *)anObject {
	if (self.dataSource && anObject && self.dataObjectID && [[anObject legislatorID] isEqual:self.dataObjectID])
		return;
	
	self.dataSource = nil;
	self.dataObjectID = nil;
	
	if (anObject) {
		self.dataObjectID = [anObject legislatorID];

		self.tableView.dataSource = self.dataSource;

		[self setupHeader];
		self.votingDataSource.legislatorID = [anObject legislatorID];

		if (masterPopover != nil) {
			[masterPopover dismissPopoverAnimated:YES];
		}		
		[self.tableView reloadData];
		[self.newChartView reloadData];
		[self.view setNeedsDisplay];
	}
}
#pragma mark -
#pragma mark Managing the popover

- (IBAction)resetTableData:(id)sender {
	// this will force our datasource to renew everything
	self.dataSource.legislator = self.legislator;
	[self.tableView reloadData];	
	[self.newChartView reloadData];
}

// Called on the delegate when the user has taken action to dismiss the popover. This is not called when -dismissPopoverAnimated: is called directly.
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[self.tableView reloadData];
	if (self.notesPopover && [self.notesPopover isEqual:popoverController]) {
		self.notesPopover = nil;
	}
}
	
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	BOOL ipad = [UtilityMethods isIPadDevice];
	BOOL portrait = (![UtilityMethods isLandscapeOrientation]);

	if (portrait && ipad && !self.legislator)
		self.legislator = [[[TexLegeAppDelegate appDelegate] legislatorMasterVC] selectObjectOnAppear];		
	
	if (self.legislator)
		[self setupHeader];
}

#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
	barButtonItem.title = @"Legislators";
	[self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
	self.masterPopover = pc;
}

// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc 
	 willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	//debug_NSLog(@"Entering landscape, hiding the button: %@", [aViewController class]);
	[self.navigationItem setRightBarButtonItem:nil animated:YES];
	self.masterPopover = nil;
}

- (void) splitViewController:(UISplitViewController *)svc popoverController: (UIPopoverController *)pc
   willPresentViewController: (UIViewController *)aViewController
{
	if ([UtilityMethods isLandscapeOrientation]) {
		[[LocalyticsSession sharedLocalyticsSession] tagEvent:@"ERR_POPOVER_IN_LANDSCAPE"];
	}
	if (self.notesPopover) {
		[self.notesPopover dismissPopoverAnimated:YES];
		self.notesPopover = nil;
	}
}

#pragma mark -
#pragma mark orientations

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
	[self.newChartView reloadData];	
}

#pragma mark -
#pragma mark Table View Delegate
// the user selected a row in the table.
- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	
	// deselect the new row using animation
	[aTableView deselectRowAtIndexPath:newIndexPath animated:YES];	
	
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:newIndexPath];
	LegislatorObj *member = self.legislator;

	if (!cellInfo.isClickable)
		return;
	
		if (cellInfo.entryType == DirectoryTypeNotes) { // We need to edit the notes thing...
			NotesViewController *nextViewController = nil;
			if ([UtilityMethods isIPadDevice])
				nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView~ipad" bundle:nil];
			else
				nextViewController = [[NotesViewController alloc] initWithNibName:@"NotesView" bundle:nil];
			
			// If we got a new view controller, push it .
			if (nextViewController) {
				nextViewController.legislator = member;
				nextViewController.backViewController = self;
				
				if ([UtilityMethods isIPadDevice]) {
					self.notesPopover = [[[UIPopoverController alloc] initWithContentViewController:nextViewController] autorelease];
					self.notesPopover.delegate = self;
					CGRect cellRect = [aTableView rectForRowAtIndexPath:newIndexPath];
					[self.notesPopover presentPopoverFromRect:cellRect inView:aTableView permittedArrowDirections:(UIPopoverArrowDirectionLeft & UIPopoverArrowDirectionRight & UIPopoverArrowDirectionDown ) animated:YES];
				}
				else {
					[self.navigationController pushViewController:nextViewController animated:YES];
				}
				
				[nextViewController release];
			}
		}
		else if (cellInfo.entryType == DirectoryTypeCommittee) {
			CommitteeDetailViewController *subDetailController = [[CommitteeDetailViewController alloc] initWithNibName:@"CommitteeDetailViewController" bundle:nil];
			subDetailController.committee = cellInfo.entryValue;
			[self.navigationController pushViewController:subDetailController animated:YES];
			[subDetailController release];
		}
		else if (cellInfo.entryType == DirectoryTypeContributions) {
			if ([TexLegeReachability canReachHostWithURL:[NSURL URLWithString:@"http://transparencydata.org"]]) { 
				LegislatorContributionsViewController *subDetailController = [[LegislatorContributionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
				[subDetailController setQueryEntityID:cellInfo.entryValue type:[NSNumber numberWithInteger:kContributionQueryRecipient] cycle:@"-1"];
				[self.navigationController pushViewController:subDetailController animated:YES];
				[subDetailController release];
			}
		}
		else if (cellInfo.entryType == DirectoryTypeBills) {
			if ([TexLegeReachability openstatesReachable]) { 
				BillsListDetailViewController *subDetailController = [[BillsListDetailViewController alloc] initWithStyle:UITableViewStylePlain];
				BillSearchDataSource *searchDS = [subDetailController valueForKey:@"dataSource"];
				subDetailController.title = [NSString stringWithFormat:@"Bills for %@", [member shortNameForButtons]];
				[searchDS startSearchForSponsor:cellInfo.entryValue];
				[self.navigationController pushViewController:subDetailController animated:YES];
				[subDetailController release];
			}
		}
		else if (cellInfo.entryType == DirectoryTypeOfficeMap) {
			CapitolMap *capMap = cellInfo.entryValue;			
			CapitolMapsDetailViewController *detailController = [[CapitolMapsDetailViewController alloc] initWithNibName:@"CapitolMapsDetailViewController" bundle:nil];
			detailController.map = capMap;
			
			[self.navigationController pushViewController:detailController animated:YES];
			[detailController release];
		}
		else if (cellInfo.entryType == DirectoryTypeMail) {
			[[TexLegeEmailComposer sharedTexLegeEmailComposer] presentMailComposerTo:cellInfo.entryValue 
																			 subject:@"" body:@"" commander:self];			
		}
		// Switch to the appropriate application for this url...
		else if (cellInfo.entryType == DirectoryTypeMap) {
			if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]] || [cellInfo.entryValue isKindOfClass:[DistrictMapObj class]])
			{		
				MapMiniDetailViewController *mapViewController = [[MapMiniDetailViewController alloc] init];
				[mapViewController view];
				
				DistrictOfficeObj *districtOffice = nil;
				if ([cellInfo.entryValue isKindOfClass:[DistrictOfficeObj class]])
					districtOffice = cellInfo.entryValue;
				
				[mapViewController resetMapViewWithAnimation:NO];
				BOOL isDistMap = NO;
				id<MKAnnotation> theAnnotation = nil;
				if (districtOffice) {
					theAnnotation = districtOffice;
					[mapViewController.mapView addAnnotation:theAnnotation];
					[mapViewController moveMapToAnnotation:theAnnotation];
				}
				else {
					theAnnotation = member.districtMap;
					[mapViewController.mapView addAnnotation:theAnnotation];
					[mapViewController moveMapToAnnotation:theAnnotation];
					[mapViewController.mapView performSelector:@selector(addOverlay:) 
													withObject:[member.districtMap polygon] afterDelay:0.5f];
					isDistMap = YES;
				}
				if (theAnnotation)
					mapViewController.navigationItem.title = [theAnnotation title];

				[self.navigationController pushViewController:mapViewController animated:YES];
				[mapViewController release];
				
				if (isDistMap)
					[[DistrictMapObj managedObjectContext] refreshObject:member.districtMap mergeChanges:NO];
			}
		}
		else if (cellInfo.entryType > kDirectoryTypeIsURLHandler &&
				 cellInfo.entryType < kDirectoryTypeIsExternalHandler) {	// handle the URL ourselves in a webView
			NSURL *myURL = [cellInfo generateURL];
			
			if ([TexLegeReachability canReachHostWithURL:myURL]) { // do we have a good URL/connection?

				if ([[myURL scheme] isEqualToString:@"twitter"])
					[[UIApplication sharedApplication] openURL:myURL];
				else {
					MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:myURL];
					[mbc display:self.tabBarController];
				}
			}
		}
		else if (cellInfo.entryType > kDirectoryTypeIsExternalHandler)		// tell the device to open the url externally
		{
			NSURL *myURL = [cellInfo generateURL];			
			BOOL isPhone = ([UtilityMethods canMakePhoneCalls]);
			
			if ((cellInfo.entryType == DirectoryTypePhone) && (!isPhone)) {
				debug_NSLog(@"Tried to make a phonecall, but this isn't a phone: %@", myURL.description);
				[UtilityMethods alertNotAPhone];
				return;
			}
			
			[UtilityMethods openURLWithoutTrepidation:myURL];
		}
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat height = 44.0f;
	TableCellDataObject *cellInfo = [self.dataSource dataObjectForIndexPath:indexPath];
	
	if (cellInfo == nil) {
		debug_NSLog(@"LegislatorDetailViewController:heightForRow: error finding table entry for section:%d row:%d", indexPath.section, indexPath.row);
		return height;
	}
	
	if ([cellInfo.subtitle rangeOfString:@"Address"].length )
		height = 98.0f;
	else if ([cellInfo.entryValue isKindOfClass:[NSString string]]) {
		NSString *tempStr = cellInfo.entryValue;
		if (!tempStr || [tempStr length] <= 0) {
			height = 0.0f;
		}
	}
	return height;
}

@end

