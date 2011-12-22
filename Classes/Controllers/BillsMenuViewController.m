//
//  BillsMenuViewController.m
//  Created by Gregory Combs on 11/6/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "BillsMenuViewController.h"
#import "SLFDataModels.h"
#import "SLFTheme.h"
#import "UIImage+OverlayColor.h"
#import "SLFRestKitManager.h"
#import "BillsViewController.h"
#import "BillSearchParameters.h"
#import "BillsSearchViewController.h"
#import "BillsWatchedViewController.h"
#import "BillsSubjectsViewController.h"

#define MenuFavorites NSLocalizedString(@"Watch List", @"")
#define MenuSearch NSLocalizedString(@"Search Bills", @"")
#define MenuRecents NSLocalizedString(@"Recently Updated (5 Days)", @"")
#define MenuSubjects NSLocalizedString(@"Bills By Subject", @"")

@interface BillsMenuViewController()
- (void)configureTableItems;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
- (void)configureTableController;
@end

@implementation BillsMenuViewController
@synthesize state = _state;
@synthesize tableController = _tableController;

- (id)initWithState:(SLFState *)newState {
    self = [super init];
    if (self) {
        self.useGearViewBackground = YES;
        self.title = NSLocalizedString(@"Bills", @"");
        self.useTitleBar = SLFIsIpad();
        [self reconfigureForState:newState];
    }
    return self;
}


- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.state = nil;
    self.tableController = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.tableController = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableController];
    if (self.state)
        self.title = [NSString stringWithFormat:@"%@ %@", self.state.name, NSLocalizedString(@"Bills",@"")]; 
}

- (void)reconfigureForState:(SLFState *)newState {
    self.state = newState;
    if (newState)
        [self loadDataFromNetworkWithID:newState.stateID];
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.state];
}

- (void)configureTableController {
    self.tableController = [RKTableController tableControllerForTableViewController:(UITableViewController*)self];
    self.tableController.delegate = self;
    self.tableController.objectManager = [RKObjectManager sharedManager];
    self.tableController.pullToRefreshEnabled = NO;
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"stateID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/metadata/:stateID?apikey=:apikey", queryParams);
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(24)];
}

- (RKTableItem *)menuItemWithText:(NSString *)text imagePrefix:(NSString *)imagePrefix {
    NSParameterAssert(text != NULL && imagePrefix != NULL);
    NSString *normalName = [imagePrefix stringByAppendingString:@"-Off"];
    NSString *highlightedName = [imagePrefix stringByAppendingString:@"-On"];
    RKTableItem *item = [RKTableItem tableItem];
    [item setText:text];
    [item setImage:[UIImage imageNamed:normalName]];
    [item setValue:[UIImage imageNamed:highlightedName] forKey:@"highlightedImage"]; // key value magic.
    return item;
}

- (void)configureTableItems {
    NSMutableArray* tableItems = [[NSMutableArray alloc] initWithCapacity:15];
    [tableItems addObject:[self menuItemWithText:MenuSearch imagePrefix:@"Magnify"]];
    [tableItems addObject:[self menuItemWithText:MenuFavorites imagePrefix:@"Star"]];
    [tableItems addObject:[self menuItemWithText:MenuRecents imagePrefix:@"Clock"]];
    if (self.state && self.state.featureFlags && [self.state.featureFlags containsObject:@"subjects"])
	    [tableItems addObject:[self menuItemWithText:MenuSubjects imagePrefix:@"Collection"]];
    RKTableViewCellMapping *cellMap = [self menuCellMapping]; // subclass can override
    [cellMap mapKeyPath:@"highlightedImage" toAttribute:@"imageView.highlightedImage"];
    [cellMap addDefaultMappings];
    [_tableController loadTableItems:tableItems withMapping:cellMap];
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
    if ([menuItem isEqualToString:MenuRecents]) {
        UIViewController *vc = nil;
        NSString *resourcePath = [BillSearchParameters pathForUpdatedSinceDaysAgo:5 state:_state.stateID];
        vc = [[BillsViewController alloc] initWithState:_state resourcePath:resourcePath];
        vc.title = [NSString stringWithFormat:@"%@: %@", [_state.stateID uppercaseString], @"Recent Updates (5 days)"];
        [self stackOrPushViewController:vc];
        [vc release];
        return;
    }
    Class controllerClass = nil;
    if ([menuItem isEqualToString:MenuSearch])
        controllerClass = [BillsSearchViewController class];
    else if ([menuItem isEqualToString:MenuFavorites])
        controllerClass = [BillsWatchedViewController class];
    else if ([menuItem isEqualToString:MenuSubjects])
        controllerClass = [BillsSubjectsViewController class];
    if (controllerClass) {
        NSString *path = [SLFActionPathNavigator navigationPathForController:controllerClass withResource:_state];
        if (!IsEmpty(path))
            [SLFActionPathNavigator navigateToPath:path skipSaving:NO fromBase:self popToRoot:NO];
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error",@"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    self.state = object;
    if (object)
        self.title = [NSString stringWithFormat:@"%@ %@", _state.name, NSLocalizedString(@"Bills",@"")]; 
    [self configureTableItems];
}

@end
