//
//  CommitteeDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "CommitteeDetailViewController.h"
#import "LegislatorDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFMappingsManager.h"
#import "SLFRestKitManager.h"
#import "SLFReachable.h"
#import "SVWebViewController.h"
#import "TableSectionHeaderView.h"
#import "LegislatorCell.h"

#define SectionHeaderCommitteeInfo NSLocalizedString(@"Committee Details", @"")
#define SectionHeaderMembers NSLocalizedString(@"Members", @"")

enum SECTIONS {
    SectionCommitteeInfoIndex = 1,
    SectionMembersIndex,
    kNumSections
};

@interface CommitteeDetailViewController()
@property (nonatomic, retain) RKTableViewModel *tableViewModel;
- (void)configureTableViewModel;
- (void)configureTableItems;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex;
- (RKTableViewCellMapping *)committeeMemberCellMap;
@end

@implementation CommitteeDetailViewController
@synthesize committee;
@synthesize tableViewModel = __tableViewModel;

- (id)initWithCommitteeID:(NSString *)committeeID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self loadDataFromNetworkWithID:committeeID];
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.committee = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.tableViewModel = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableViewModel];
	self.title = NSLocalizedString(@"Loading...", @"");
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"committeeID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/committees/:committeeID?apikey=:apikey", queryParams);
    SLFSaveCurrentActivityPath(resourcePath);
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(24)];
}

- (void)configureTableViewModel {
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    __tableViewModel.delegate = self;
    __tableViewModel.objectManager = [RKObjectManager sharedManager];
    __tableViewModel.pullToRefreshEnabled = NO;
    __tableViewModel.variableHeightRows = YES;
    [__tableViewModel mapObjectsWithClass:[CommitteeMember class] toTableCellsWithMapping:[self committeeMemberCellMap]];
    NSInteger sectionIndex;
    for (sectionIndex = SectionCommitteeInfoIndex;sectionIndex < kNumSections; sectionIndex++) {
        [__tableViewModel addSectionWithBlock:^(RKTableViewSection *section) {
            NSString *headerTitle = [self headerForSectionIndex:sectionIndex];
            TableSectionHeaderView *sectionView = [[TableSectionHeaderView alloc] initWithTitle:headerTitle width:self.tableView.width];
            section.headerTitle = headerTitle;
            section.headerHeight = TableSectionHeaderViewDefaultHeight;
            section.headerView = sectionView;
            [sectionView release];
        }];
    }         
}

- (void)configureTableItems {
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    RKTableItem *firstItemCell = [RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.cellMapping = [StaticSubtitleCellMapping cellMapping];
        tableItem.cellMapping.style = UITableViewCellStyleValue1;
        tableItem.text = self.committee.committeeName;
    }];
    [tableItems addObject:firstItemCell];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.cellMapping = [StaticSubtitleCellMapping cellMapping];
        tableItem.text = self.committee.chamberObj.shortName;
        tableItem.detailText = self.committee.subcommittee;
    }]];
    for (GenericAsset *source in self.committee.sources) {
        NSString *subtitle = source.name;
        if (IsEmpty(subtitle))
            subtitle = source.url;
        [tableItems addObject:[self webPageItemWithTitle:NSLocalizedString(@"Web Site", @"") subtitle:subtitle url:source.url]];
    }
    [__tableViewModel loadTableItems:tableItems inSection:SectionCommitteeInfoIndex];
    [tableItems release];
    [__tableViewModel loadObjects:self.committee.sortedMembers inSection:SectionMembersIndex];    
}

- (RKTableViewCellMapping *)committeeMemberCellMap {
    FoundLegislatorCellMapping *cellMap = [FoundLegislatorCellMapping cellMappingWithBlock:^(RKTableViewCellMapping* cellMapping) {
        [cellMapping mapKeyPath:@"foundLegislator" toAttribute:@"legislator"];
        [cellMapping mapKeyPath:@"type" toAttribute:@"role"];
        [cellMapping mapKeyPath:@"name" toAttribute:@"genericName"];
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
            NSString *legID = [object valueForKey:@"legID"];
            LegislatorDetailViewController *vc = [[LegislatorDetailViewController alloc] initWithLegislatorID:legID];
            [self stackOrPushViewController:vc];
            [vc release];
        };
    }];
    return cellMap;
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    if (object && [object isKindOfClass:[SLFCommittee class]])
        self.committee = object;
    if (self.committee)
        self.title = self.committee.committeeName;
    if (![self isViewLoaded]) { // finished loading too soon?  Would this ever happen?
        [self performSelector:@selector(objectLoader:didLoadObject:) withObject:object afterDelay:2];
        return;
    }
    [self configureTableItems];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error",@"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex {
    switch (sectionIndex) {
        case SectionCommitteeInfoIndex:
            return SectionHeaderCommitteeInfo;
        case SectionMembersIndex:
            return SectionHeaderMembers;
        default:
            return @"";
    }
}

@end
