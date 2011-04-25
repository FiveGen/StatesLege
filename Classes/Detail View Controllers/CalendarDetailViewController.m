//
//  CalendarDetailViewController.m
//  TexLege
//
//  Created by Gregory Combs on 7/29/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//
#import "CalendarDetailViewController.h"
#import "CalendarMasterViewController.h"
#import "UtilityMethods.h"
#import "MiniBrowserController.h"
#import "TexLegeAppDelegate.h"
#import "ChamberCalendarObj.h"
#import "TexLegeTheme.h"
#import "LocalyticsSession.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "CalendarEventsLoader.h"

@interface CalendarDetailViewController (Private) 
	
@end

@implementation CalendarDetailViewController
@synthesize chamberCalendar;
@synthesize webView;
@synthesize masterPopover;

+ (NSString *)nibName {
	if ([UtilityMethods isIPadDevice])
		return @"CalendarDetailViewController~ipad";
	else
		return @"CalendarDetailViewController~iphone";	
}

- (NSString *)nibName {
	return [CalendarDetailViewController nibName];	
}

- (void)finalizeUI {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadEvents:) name:kCalendarEventsNotifyLoaded object:nil];	

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadEvents:) name:kCalendarEventsNotifyError object:nil];	

	if ([UtilityMethods isIPadDevice]) {
		UIImage *sealImage = [UIImage imageNamed:@"seal.png"];
		UIColor *sealColor = [UIColor colorWithPatternImage:sealImage];		
		self.view.backgroundColor = sealColor;
	}
	//self.navigationItem.title = @"Upcoming Committee Meetings";
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];
	self.searchDisplayController.searchBar.tintColor = [TexLegeTheme navbar];
	self.navigationItem.titleView = self.searchDisplayController.searchBar;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	if (!self.webView && [UtilityMethods isIPadDevice]) {
		[[NSBundle mainBundle] loadNibNamed:[self nibName] owner:self options:nil];
	}
	
	[self finalizeUI];
}	

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self finalizeUI];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super viewDidUnload];
}

- (void)didReceiveMemoryWarning {
	UINavigationController *nav = [self navigationController];
	//if (nav && [nav.viewControllers count]>1)
	[nav popToRootViewControllerAnimated:YES];
	
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	self.chamberCalendar = nil;
	self.webView = nil;
	self.masterPopover = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationBar.tintColor = [TexLegeTheme navbar];

	[[CalendarEventsLoader sharedCalendarEventsLoader] events];
	
	if ([UtilityMethods isIPadDevice] && !self.chamberCalendar && ![UtilityMethods isLandscapeOrientation])  {
		TexLegeAppDelegate *appDelegate = [TexLegeAppDelegate appDelegate];
		
		self.chamberCalendar = [[appDelegate calendarMasterVC] selectObjectOnAppear];		
	}
	
	if (self.chamberCalendar)
		self.searchDisplayController.searchBar.placeholder = self.chamberCalendar.title;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([UtilityMethods isIPadDevice])
		return YES;
	else
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark -
#pragma mark Data Objects

- (void)reloadEvents:(NSNotification*)notification {
	[self reloadData];
}

- (id)dataObject {
	return self.chamberCalendar;
}

- (void)setDataObject:(id)newObj {
	[self setChamberCalendar:newObj];
}

- (void)setChamberCalendar:(ChamberCalendarObj *)newObj {
	if (chamberCalendar && newObj && self.webView) {
		if (![[chamberCalendar valueForKey:@"title"] isEqualToString:[newObj valueForKey:@"title"]])
			[self.webView loadHTMLString:@"<html></html>" baseURL:nil];
	}
	
	if (chamberCalendar) [chamberCalendar release], chamberCalendar = nil;
	if (newObj) {
		if (masterPopover)
			[masterPopover dismissPopoverAnimated:YES];
		
		chamberCalendar = [newObj retain];
		
		[self view];
		
		[self setDelegate:self];
		[self setDataSource:chamberCalendar];
		[self.searchDisplayController setSearchResultsDataSource:chamberCalendar];
				
		[self showAndSelectDate:[NSDate date]];
	}
}

#pragma mark -
#pragma mark Popover Support


- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	//debug_NSLog(@"Entering portrait, showing the button: %@", [aViewController class]);
    barButtonItem.title = @"Meetings";
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    self.masterPopover = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
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
}	

#pragma -
#pragma UITableViewDelegate


- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	NSDictionary *eventDict = [self.chamberCalendar eventForIndexPath:indexPath];
	if (eventDict)
		[[CalendarEventsLoader sharedCalendarEventsLoader] addEventToiCal:eventDict delegate:self.navigationController];	
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *eventDict = [self.chamberCalendar eventForIndexPath:indexPath];
	
	if (tv == self.searchDisplayController.searchResultsTableView) {
		[self.searchDisplayController setActive:NO animated:YES];
		[self showAndSelectDate:[eventDict objectForKey:kCalendarEventsLocalizedDateKey]];
	}
		
	NSURL *url = [NSURL URLWithString:[eventDict objectForKey:kCalendarEventsAnnouncementURLKey]];
	
	if ([TexLegeReachability canReachHostWithURL:url]) { // do we have a good URL/connection?
		if ([UtilityMethods isIPadDevice]) {	
			NSURLRequest *urlReq = [NSURLRequest requestWithURL:url 
													cachePolicy:NSURLRequestUseProtocolCachePolicy 
												timeoutInterval:60.0];
			if (urlReq)
				[self.webView loadRequest:urlReq];	
		}
		else {
			MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:url];				
			[mbc display:self.tabBarController];
		}		
	}
}

#pragma mark -
#pragma mark Search Results Delegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
	id gridView = [self.view valueForKey:@"gridView"];
	if (gridView && [gridView respondsToSelector:@selector(setAlpha:)])
		[gridView setAlpha:0.4f];
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
	id gridView = [self.view valueForKey:@"gridView"];
	if (gridView && [gridView respondsToSelector:@selector(setAlpha:)])
		[gridView setAlpha:1.0f];
	
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
	//NSArray *foundItems = 
		[self.chamberCalendar filterEventsByString:searchString];
	
	return YES; // or foundSomething?
}


@end
