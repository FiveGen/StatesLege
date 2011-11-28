//
//  StateDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "StateDetailViewController.h"
#import "LegislatorsViewController.h"
#import "CommitteesViewController.h"
#import "DistrictsViewController.h"
#import "EventsViewController.h"
#import "BillsMenuViewController.h"
#import "SLFDataModels.h"
#import "SLFTheme.h"
#import "UIImage+OverlayColor.h"
#import "SVWebViewController.h"
#import "SLFReachable.h"
#import "SLFRestKitManager.h"

#define MenuLegislators NSLocalizedString(@"Legislators", @"")
#define MenuCommittees NSLocalizedString(@"Committees", @"")
#define MenuDistricts NSLocalizedString(@"District Maps", @"")
#define MenuBills NSLocalizedString(@"Bills", @"")
#define MenuEvents NSLocalizedString(@"Events", @"")
#define MenuNews NSLocalizedString(@"News", @"")

@interface StateDetailViewController()
- (void)configureTableItems;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
@property (nonatomic,retain) UIImage *legislatorsIcon;
@property (nonatomic,retain) UIImage *committeesIcon;
@property (nonatomic,retain) UIImage *districtsIcon;
@property (nonatomic,retain) UIImage *eventsIcon;
@property (nonatomic,retain) UIImage *billsIcon;
@property (nonatomic,retain) UIImage *newsIcon;
@end

@implementation StateDetailViewController
@synthesize state;
@synthesize tableViewModel = __tableViewModel;
@synthesize legislatorsIcon;
@synthesize committeesIcon;
@synthesize districtsIcon;
@synthesize eventsIcon;
@synthesize billsIcon;
@synthesize newsIcon;

- (id)initWithState:(SLFState *)newState {
    self = [super init];
    if (self) {
        UIColor *iconColor = [SLFAppearance menuTextColor];
        self.legislatorsIcon = [[UIImage imageNamed:@"123-id-card"] imageWithOverlayColor:iconColor];
        self.committeesIcon = [[UIImage imageNamed:@"60-signpost"] imageWithOverlayColor:iconColor];                               
        self.districtsIcon = [[UIImage imageNamed:@"73-radar"] imageWithOverlayColor:iconColor];
        self.billsIcon = [[UIImage imageNamed:@"gavel"] imageWithOverlayColor:iconColor];
        self.eventsIcon = [[UIImage imageNamed:@"83-calendar"] imageWithOverlayColor:iconColor];
        self.newsIcon = [[UIImage imageNamed:@"166-newspaper"] imageWithOverlayColor:iconColor];
        [self stateMenuSelectionDidChangeWithState:newState];
    }
    return self;
}

- (void)stateMenuSelectionDidChangeWithState:(SLFState *)newState {
    self.state = newState;
    if (newState)
        [self loadDataFromNetworkWithID:newState.stateID];
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.state = nil;
    self.tableViewModel = nil;
    self.legislatorsIcon = nil;
    self.committeesIcon = nil;
    self.districtsIcon = nil;
    self.eventsIcon = nil;
    self.billsIcon = nil;
    self.newsIcon = nil;
    [super dealloc];
}

- (void)configureTableViewModel {
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    self.tableViewModel.delegate = self;
    self.tableViewModel.objectManager = [RKObjectManager sharedManager];
    self.tableViewModel.pullToRefreshEnabled = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableViewModel];
    if (self.state)
        self.title = self.state.name; 
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"stateID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/metadata/:stateID?apikey=:apikey", queryParams);
    SLFSaveCurrentActivityPath(resourcePath);
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(48)];
}

- (void)configureTableItems {
    NSMutableArray* tableItems = [[NSMutableArray alloc] initWithCapacity:15];
    [tableItems addObject:[RKTableItem tableItemWithText:MenuLegislators detailText:nil image:self.legislatorsIcon]];
    [tableItems addObject:[RKTableItem tableItemWithText:MenuCommittees detailText:nil image:self.committeesIcon]];
    [tableItems addObject:[RKTableItem tableItemWithText:MenuDistricts detailText:nil image:self.districtsIcon]];
    [tableItems addObject:[RKTableItem tableItemWithText:MenuBills detailText:nil image:self.billsIcon]];
    if (self.state && self.state.featureFlags && [self.state.featureFlags containsObject:@"events"])
        [tableItems addObject:[RKTableItem tableItemWithText:MenuEvents detailText:nil image:self.eventsIcon]];
    [tableItems addObject:[RKTableItem tableItemWithText:MenuNews detailText:nil image:self.newsIcon]];
    [self.tableViewModel loadTableItems:tableItems withMapping:[self menuCellMapping]];
    [tableItems release];
}

- (RKTableViewCellMapping *)menuCellMapping {
    SubtitleCellMapping *cellMap = [SubtitleCellMapping cellMapping];
    cellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
        RKTableItem* tableItem = (RKTableItem*) object;
        [self selectMenuItem:tableItem.text];
    };
    return cellMap;
}

- (void)selectMenuItem:(NSString *)menuItem {
	if (menuItem == NULL)
        return;
    UIViewController *vc = nil;
    if ([menuItem isEqualToString:MenuLegislators])
        vc = [[LegislatorsViewController alloc] initWithState:self.state];
    else if ([menuItem isEqualToString:MenuCommittees])
        vc = [[CommitteesViewController alloc] initWithState:self.state];
    else if ([menuItem isEqualToString:MenuDistricts])
        vc = [[DistrictsViewController alloc] initWithState:self.state];
    else if ([menuItem isEqualToString:MenuEvents])
        vc = [[EventsViewController alloc] initWithState:self.state];
    else if ([menuItem isEqualToString:MenuBills])
        vc = [[BillsMenuViewController alloc] initWithState:self.state];
    else if ([menuItem isEqualToString:MenuNews]) {
        if (SLFIsReachableAddress(self.state.newsAddress)) {
            SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:self.state.newsAddress];
            webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
            [self presentModalViewController:webViewController animated:YES];	
            [webViewController release];
        }
    }
    
    if (vc) {
        [self stackOrPushViewController:vc];
        [vc release];
    }
}
- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error",@"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    self.state = object;
    if (self.state)
        self.title = self.state.name;
    if (![self isViewLoaded]) { // finished loading too soon?  Would this ever happen?
        [self performSelector:@selector(objectLoader:didLoadObject:) withObject:object afterDelay:2];
        return;
    }
    [self configureTableItems];
}

@end
