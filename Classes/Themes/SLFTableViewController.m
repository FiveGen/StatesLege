//
//  SLFTableViewController.m
//  Created by Greg Combs on 9/26/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "SLFTableViewController.h"
#import "SLFAppearance.h"
#import "GradientBackgroundView.h"
#import "SVWebViewController.h"
#import "SLFReachable.h"
#import "SLFDataModels.h"
#import "SLFActionPathRegistry.h"

@implementation SLFTableViewController
@synthesize useGradientBackground;
@synthesize useTitleBar;
@synthesize titleBarView = _titleBarView;
@synthesize useGearViewBackground = _useGearViewBackground;
@synthesize onSavePersistentActionPath = _onSavePersistentActionPath;
@synthesize searchBar = _searchBar;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.stackWidth = 450;
        _useGearViewBackground = style == UITableViewStyleGrouped;
        self.useGradientBackground = YES;
        self.useTitleBar = NO;
    }
    return self;
}

- (void)dealloc {
    self.titleBarView = nil;
    self.onSavePersistentActionPath = nil;
    self.searchBar = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    self.titleBarView = nil;
    self.searchBar = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.useTitleBar) {
        _titleBarView = [[TitleBarView alloc] initWithFrame:self.view.bounds title:self.title];
        CGRect tableRect = self.tableView.frame;
        tableRect.size.height -= _titleBarView.opticalHeight;
        self.tableView.frame = CGRectOffset(tableRect, 0, _titleBarView.opticalHeight);
        [self.view addSubview:_titleBarView];
    }
    if (self.useGradientBackground) {
        GradientBackgroundView *gradient = [[GradientBackgroundView alloc] initWithFrame:self.tableView.bounds];
        gradient.useGearView = _useGearViewBackground;
        [gradient loadLayerAndGradientColors];
        self.tableView.backgroundView = gradient;
        [gradient release];
    }
}

- (UITableView *)tableViewWithStyle:(UITableViewStyle)style {
    UITableView *aTableView = [super tableViewWithStyle:style];
    aTableView.backgroundColor = [UIColor clearColor];
    if (style == UITableViewStylePlain)
        aTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    return aTableView;
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:nil];
}

+ (NSString *)actionPathForObject:(id)object {
    NSString *pattern = [SLFActionPathRegistry patternForClass:[self class]];
    if (!pattern)
        return nil;
    if (!object)
        return pattern;
    return RKMakePathWithObjectAddingEscapes(pattern, object, NO);
}

- (void)setOnSavePersistentActionPath:(SLFPersistentActionsSaveBlock)onSavePersistentActionPath {
    if (_onSavePersistentActionPath) {
        Block_release(_onSavePersistentActionPath);
        _onSavePersistentActionPath = nil;
    }
    _onSavePersistentActionPath = Block_copy(onSavePersistentActionPath);
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    if (self.useTitleBar && self.isViewLoaded)
        self.titleBarView.title = title;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)tableController:(RKAbstractTableController*)tableController willLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader {
    objectLoader.URLRequest.timeoutInterval = 30; // something reasonable;
}

- (void)tableController:(RKAbstractTableController*)tableController didFailLoadWithError:(NSError*)error {
    self.onSavePersistentActionPath = nil;
    self.title = NSLocalizedString(@"Server Error",@"");
    RKLogError(@"Error loading table: %@", error);
    if ([tableController respondsToSelector:@selector(resourcePath)])
        RKLogError(@"-------- from resource path: %@", [tableController performSelector:@selector(resourcePath)]);
}

- (void)tableControllerDidFinishFinalLoad:(RKAbstractTableController*)tableController {
    RKLogTrace(@"%@: Table controller finished loading.", NSStringFromClass([self class]));
    if (self.onSavePersistentActionPath) {
        _onSavePersistentActionPath(self.actionPath);
        self.onSavePersistentActionPath = nil;
    }
}

- (void)stackOrPushViewController:(UIViewController *)viewController {
    if (!SLFIsIpad())
        [self.navigationController pushViewController:viewController animated:YES];
    else
        [self.stackController pushViewController:viewController fromViewController:self animated:YES];
}

- (void)popToThisViewController {
    if (!SLFIsIpad())
        [SLFAppDelegateNav popToViewController:self animated:YES];
    else
        [SLFAppDelegateStack popToViewController:self animated:YES];
}

- (RKTableItem *)webPageItemWithTitle:(NSString *)itemTitle subtitle:(NSString *)itemSubtitle url:(NSString *)url {
    NSParameterAssert(!IsEmpty(url));
    return [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [SubtitleCellMapping cellMapping];
        tableItem.text = itemTitle;
        tableItem.detailText = itemSubtitle;
        tableItem.URL = url;
        tableItem.cellMapping.onSelectCell = ^(void) {
            if (SLFIsReachableAddress(url)) {
                SVWebViewController *webViewController = [[SVWebViewController alloc] initWithAddress:url];
                webViewController.modalPresentationStyle = UIModalPresentationPageSheet;
                [self presentModalViewController:webViewController animated:YES];	
                [webViewController release];
            }
        };
    }];
}

#pragma mark - Search Bar Scope

- (void)configureSearchBarWithPlaceholder:(NSString *)placeholder withConfigurationBlock:(SearchBarConfigurationBlock)block {
    CGFloat tableWidth = self.tableView.bounds.size.width;
    CGRect searchRect = CGRectMake(0, self.titleBarView.opticalHeight, tableWidth, 44);
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:searchRect];
    searchBar.delegate = self;
    searchBar.placeholder = placeholder;
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    if (block)
        block(searchBar);
    [searchBar sizeToFit];
    searchBar.width = tableWidth;
    CGRect tableRect = self.tableView.frame;
    tableRect.size.height -= searchBar.height;
    self.tableView.frame = CGRectOffset(tableRect, 0, searchBar.height);
    [self.view addSubview:searchBar];
    self.searchBar = searchBar;
    [searchBar release];
}

- (void)configureChamberScopeTitlesForSearchBar:(UISearchBar *)searchBar withState:(SLFState *)state{
    NSParameterAssert(searchBar != NULL);
    NSArray *buttonTitles = [SLFChamber chamberSearchScopeTitlesWithState:state];
    if (IsEmpty(buttonTitles))
        return;
    searchBar.showsScopeBar = YES;
    searchBar.scopeButtonTitles = buttonTitles;
    searchBar.selectedScopeButtonIndex = SLFSelectedScopeIndexForKey(NSStringFromClass([self class]));
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    SLFSaveSelectedScopeIndexForKey(selectedScope, NSStringFromClass([self class]));
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (IsEmpty(searchBar.text)) {
        searchBar.showsCancelButton = NO;
        [searchBar resignFirstResponder];
        return;
    }
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = nil;
    searchBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
}

@end
