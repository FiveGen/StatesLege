//
//  LegislatorDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "LegislatorDetailViewController.h"
#import "CommitteeDetailViewController.h"
#import "DistrictDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFMappingsManager.h"
#import "SLFRestKitManager.h"
#import "TableItem.h"

#define SectionHeaderMemberInfo NSLocalizedString(@"Member Details", @"")
#define SectionHeaderDistrict NSLocalizedString(@"District Map", @"")
#define SectionHeaderCommittees NSLocalizedString(@"Committees", @"")
#define SectionHeaderBills NSLocalizedString(@"Legislation", @"")

enum SECTIONS {
    SectionMemberInfoIndex = 1,
    SectionDistrictIndex,
    SectionCommitteesIndex,
    SectionBillsIndex,
    kNumSections
};

@interface LegislatorDetailViewController()
@property (nonatomic, retain) RKTableViewModel *tableViewModel;

- (void)configureTableItems;
- (void)loadDataFromNetworkWithID:(NSString *)resourceID;
- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex;
- (RKTableViewCellMapping *)committeeRoleCellMap;
@end

@implementation LegislatorDetailViewController
@synthesize legislator;
@synthesize tableViewModel;

- (id)initWithLegislatorID:(NSString *)legislatorID {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self loadDataFromNetworkWithID:legislatorID];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    self.tableViewModel.delegate = self;
    self.tableViewModel.variableHeightRows = YES;
    self.tableViewModel.objectManager = [RKObjectManager sharedManager];
    self.tableViewModel.pullToRefreshEnabled = NO;
    [self.tableViewModel mapObjectsWithClass:[CommitteeRole class] toTableCellsWithMapping:[self committeeRoleCellMap]];

    NSInteger sectionIndex;
    for (sectionIndex = SectionMemberInfoIndex;sectionIndex < kNumSections; sectionIndex++) {
        [self.tableViewModel addSectionWithBlock:^(RKTableViewSection *section) {
            section.headerTitle = [self headerForSectionIndex:sectionIndex];
            section.headerHeight = 22;
        }];
    }         
	self.title = NSLocalizedString(@"Loading...", @"");
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.legislator = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)loadDataFromNetworkWithID:(NSString *)resourceID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", resourceID, @"legislatorID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/legislators/:legislatorID?apikey=:apikey", queryParams);
    RKObjectManager* objectManager = [RKObjectManager sharedManager];
    [objectManager loadObjectsAtResourcePath:resourcePath delegate:self block:^(RKObjectLoader* loader) {
        loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[SLFLegislator class]];
    }];
}

- (void)configureTableItems {
    
    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSData *imageData = nil;
    UIImage *image = nil;
    if (!IsEmpty(self.legislator.photoURL))
        imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:self.legislator.photoURL] options:NSDataReadingMappedIfSafe error:&error];
    if (!error && imageData)
        image = [[UIImage alloc] initWithData:imageData];
    RKTableItem *firstItemCell = [StaticSubtitleTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.text = self.legislator.demoLongName;
        tableItem.cellMapping.style = UITableViewCellStyleValue1;
        if (image) {
            tableItem.cellMapping.rowHeight = 88;
            tableItem.image = image;
        }
    }];
    [tableItems addObject:firstItemCell];
    [tableItems addObject:[StaticSubtitleTableItem tableItemWithText:self.legislator.title detailText:self.legislator.term]];
    for (NSString *website in self.legislator.sources)
        [tableItems addObject:[SubtitleTableItem tableItemWithText:NSLocalizedString(@"Web Site", @"") URL:website]];  
    [self.tableViewModel loadTableItems:tableItems inSection:SectionMemberInfoIndex];

    [self.tableViewModel loadObjects:self.legislator.sortedRoles inSection:SectionCommitteesIndex];

    [tableItems removeAllObjects];
    [tableItems addObject:[SubtitleTableItem tableItemWithBlock:^(RKTableItem *tableItem) {
        tableItem.text = self.legislator.districtMapLabel;
        tableItem.detailText = NSLocalizedString(@"Map", @"");
        tableItem.cellMapping.onSelectCell = ^(void) {
            DistrictDetailViewController *vc = [[DistrictDetailViewController alloc] initWithDistrictMapID:self.legislator.districtID];
            [self.navigationController pushViewController:vc animated:YES];
            [vc release];
        };
    }]];
    [self.tableViewModel loadTableItems:tableItems inSection:SectionDistrictIndex];
    if (image)
        [image release];
    if (imageData)
        [imageData release];
    [tableItems release];
}

- (RKTableViewCellMapping *)committeeRoleCellMap {
    RKTableViewCellMapping *roleCellMap = [RKTableViewCellMapping cellMapping];
    roleCellMap.style = UITableViewCellStyleSubtitle;
    roleCellMap.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [roleCellMap mapKeyPath:@"committeeName" toAttribute:@"textLabel.text"];
    [roleCellMap mapKeyPath:@"role" toAttribute:@"detailTextLabel.text"];
    roleCellMap.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath *indexPath) {
        CommitteeRole *role = object;
        CommitteeDetailViewController *vc = [[CommitteeDetailViewController alloc] initWithCommitteeID:role.committeeID];
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    };
    return roleCellMap;
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error", @"");
    RKLogError(@"Error loading %@, %@", objectLoader.resourcePath, error);
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    if (object && [object isKindOfClass:[SLFLegislator class]])
        self.legislator = object;
    if (self.legislator)
        self.title = self.legislator.shortNameForButtons;
    if (![self isViewLoaded]) { // finished loading too soon?  Would this ever happen?
        [self performSelector:@selector(objectLoader:didLoadObject:) withObject:object afterDelay:2];
        return;
    }
    [self configureTableItems];
}

- (NSString *)headerForSectionIndex:(NSInteger)sectionIndex {
    switch (sectionIndex) {
        case SectionMemberInfoIndex:
            return SectionHeaderMemberInfo;
        case SectionDistrictIndex:
            return SectionHeaderDistrict;
        case SectionCommitteesIndex:
            return SectionHeaderCommittees;
        case SectionBillsIndex:
            return SectionHeaderBills;
        default:
            return @"";
    }
}


@end
