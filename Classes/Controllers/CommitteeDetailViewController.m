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

#define SectionHeaderCommitteeInfo NSLocalizedString(@"Committee Details", @"")
#define SectionHeaderMembers NSLocalizedString(@"Members", @"")

enum SECTIONS {
    SectionCommitteeInfoIndex = 1,
    SectionMembersIndex,
    kNumSections
};

@interface CommitteeDetailViewController()
@property (nonatomic, retain) RKTableViewModel *tableViewModel;

- (void)configureTableItems;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex;
- (AlternatingCellMapping *)committeeMemberCellMap;
@end

@implementation CommitteeDetailViewController
@synthesize committee;
@synthesize tableViewModel;

- (id)initWithCommitteeID:(NSString *)committeeID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [self loadDataFromNetworkWithID:committeeID];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    self.tableViewModel.delegate = self;
    self.tableViewModel.objectManager = [RKObjectManager sharedManager];
    self.tableViewModel.pullToRefreshEnabled = NO;
    [self.tableViewModel mapObjectsWithClass:[CommitteeMember class] toTableCellsWithMapping:[self committeeMemberCellMap]];
    
    NSInteger sectionIndex;
    for (sectionIndex = SectionCommitteeInfoIndex;sectionIndex < kNumSections; sectionIndex++) {
        [self.tableViewModel addSectionWithBlock:^(RKTableViewSection *section) {
            section.headerTitle = [self headerForSectionIndex:sectionIndex];
            section.headerHeight = 22;
        }];
    }         
	self.title = NSLocalizedString(@"Loading...", @"");
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.committee = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"committeeID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/committees/:committeeID?apikey=:apikey", queryParams);
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:resourcePath delegate:self block:^(RKObjectLoader* loader) {
        loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[SLFCommittee class]];
    }];
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
        tableItem.text = self.committee.chamberShortName;
        tableItem.detailText = self.committee.subcommittee;
    }]];
     for (NSString *website in self.committee.sources)
     [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem *tableItem) {
        tableItem.cellMapping = [SubtitleCellMapping cellMapping];
        tableItem.text = NSLocalizedString(@"Web Site", @"");
        tableItem.detailText = website;
        tableItem.URL = website;
    }]];  
    [self.tableViewModel loadTableItems:tableItems inSection:SectionCommitteeInfoIndex];
    [tableItems release];
    
    [self.tableViewModel loadObjects:self.committee.sortedMembers inSection:SectionMembersIndex];    
}

- (SubtitleCellMapping *)committeeMemberCellMap {
    SubtitleCellMapping *cellMap = [SubtitleCellMapping cellMapping];
    [cellMap mapKeyPath:@"legislatorName" toAttribute:@"textLabel.text"];
    [cellMap mapKeyPath:@"role" toAttribute:@"detailTextLabel.text"];
    cellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
        CommitteeMember *leg = object;
        LegislatorDetailViewController *vc = [[LegislatorDetailViewController alloc] initWithLegislatorID:leg.legID];
        [self stackOrPushViewController:vc];
        [vc release];
    };
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
    RKLogError(@"Error while loading committee detail table: %@, %@", objectLoader.resourcePath, error);
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
