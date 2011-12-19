//
//  EventDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "EventDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFTheme.h"
#import "SLFMappingsManager.h"
#import "SLFRestKitManager.h"
#import "SLFReachable.h"
#import "SVWebViewController.h"
#import "TableSectionHeaderView.h"
#import "NSDate+SLFDateHelper.h"
#import "SLFEventsManager.h"

#define SectionHeaderEventInfo NSLocalizedString(@"Event Details", @"")
#define SectionHeaderParticipants NSLocalizedString(@"Participants", @"")
#define SectionHeaderAdditional NSLocalizedString(@"Additional Info", @"")
#define SectionHeaderNotifications NSLocalizedString(@"Notifications", @"")

enum SECTIONS {
    SECTION_EVENT_INFO = 1,
    SECTION_PARTICIPANTS,
    SECTION_ADDITIONAL,
    SECTION_NOTIFICATIONS,
    kNumSections
};

@interface EventDetailViewController()
- (void)reconfigureForEvent:(SLFEvent *)event;
- (void)configureTableViewModel;
- (void)configureTableItems;
- (void)configureEventInfo;
- (void)configureParticipants;
- (void)configureAdditional;
- (void)configureNotifications;
- (void)calendarDidChange:(NSNotification *)notification;
- (NSString *)headerForSectionIndex:(NSInteger)index;
- (RKTableViewCellMapping *)participantCellMap;
@end

@implementation EventDetailViewController
@synthesize event = _event;
@synthesize tableViewModel = __tableViewModel;

- (id)initWithResourcePath:(NSString *)resourcePath {
self = [super initWithStyle:UITableViewStyleGrouped];
if (self) {
    self.useTitleBar = YES;
    self.stackWidth = 500;
    RKLogDebug(@"Loading resource path for bill: %@", resourcePath);
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
}
return self;
}

- (id)initWithEventID:(NSString *)eventID {
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:SUNLIGHT_APIKEY,@"apikey", eventID, @"eventID", nil];
    NSString *resourcePath = RKMakePathWithObject(@"/events/:eventID?apikey=:apikey", queryParams);
    self = [self initWithResourcePath:resourcePath];
    return self;
}

- (id)initWithEvent:(SLFEvent *)event {
    self = [self initWithEventID:event.eventID];
    if (self) {
        self.event = event;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
	self.event = nil;
    self.tableViewModel = nil;
    [super dealloc];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.tableViewModel = nil;
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureTableViewModel];
	self.title = NSLocalizedString(@"Loading...", @"");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(calendarDidChange:) name:SLFEventsManagerNotifyCalendarDidChange object:nil];
}

- (void)configureTableViewModel {
    self.tableViewModel = [RKTableViewModel tableViewModelForTableViewController:(UITableViewController*)self];
    __tableViewModel.delegate = self;
    __tableViewModel.variableHeightRows = YES;
    __tableViewModel.objectManager = [RKObjectManager sharedManager];
    __tableViewModel.pullToRefreshEnabled = NO;
    NSInteger sectionIndex;
    for (sectionIndex = SECTION_EVENT_INFO;sectionIndex < kNumSections; sectionIndex++) {
        [__tableViewModel addSectionWithBlock:^(RKTableViewSection *section) {
            NSString *headerTitle = [self headerForSectionIndex:sectionIndex];
            TableSectionHeaderView *sectionView = [[TableSectionHeaderView alloc] initWithTitle:headerTitle width:self.tableView.width];
            section.headerTitle = headerTitle;
            section.headerHeight = TableSectionHeaderViewDefaultHeight;
            section.headerView = sectionView;
            [sectionView release];
        }];
    }
    [self.tableViewModel mapObjectsWithClass:[EventParticipant class] toTableCellsWithMapping:[self participantCellMap]];
}

- (NSString *)actionPath {
    return [[self class] actionPathForObject:self.event];
}

- (void)reconfigureForEvent:(SLFEvent *)event {
    self.event = event;
    if (!event || !self.tableViewModel)
        return;
    self.title = event.title;
    [self configureTableItems];
}

- (void)configureTableItems {
    [self configureEventInfo];     
    [self configureParticipants];
    [self configureAdditional];
    [self configureNotifications];
}

- (RKTableViewCellMapping *)eventTableCellMap {
    StaticSubtitleCellMapping *cellMapping = [StaticSubtitleCellMapping cellMapping];
    cellMapping.style = UITableViewCellStyleValue2;
    cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
        cell.detailTextLabel.textColor = [SLFAppearance cellTextColor];
        cell.detailTextLabel.font = SLFFont(14);
        cell.textLabel.textColor = [SLFAppearance cellSecondaryTextColor];
        cell.textLabel.font = SLFFont(12);
        SLFAlternateCellForIndexPath(cell, indexPath);
        cell.detailTextLabel.lineBreakMode = UILineBreakModeTailTruncation;
    };
    return cellMapping;
}

- (void)configureEventInfo {
    RKTableViewCellMapping *cellMapping = [self eventTableCellMap];

    NSMutableArray* tableItems  = [[NSMutableArray alloc] init];
    if (!IsEmpty(_event.type)) {
        [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
            tableItem.cellMapping = cellMapping;
            tableItem.detailText = [[_event.type stringByReplacingOccurrencesOfString:@":" withString:@" "] capitalizedString];
            tableItem.text = NSLocalizedString(@"Type",@"");
        }]];
    }
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.cellMapping = cellMapping;
        tableItem.detailText = _event.title;
        tableItem.text = NSLocalizedString(@"Description",@"");
    }]];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.cellMapping = cellMapping;
        tableItem.detailText = _event.location;
        tableItem.text = NSLocalizedString(@"Location",@"");
    }]];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.cellMapping = cellMapping;
        tableItem.detailText = _event.dateStartForDisplay;
        tableItem.text = NSLocalizedString(@"Starts At",@"");
    }]];
    if (_event.dateEnd) {
        [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
            tableItem.cellMapping = cellMapping;
            tableItem.detailText = [_event.dateEnd stringWithDateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
            tableItem.text = NSLocalizedString(@"Ends At",@"");
        }]];
    }
    [__tableViewModel loadTableItems:tableItems inSection:SECTION_EVENT_INFO];
    [tableItems release];
}

- (void)configureAdditional {
    NSMutableArray *tableItems = [[NSMutableArray alloc] init];
    if (!IsEmpty(_event.link))
        [tableItems addObject:[self webPageItemWithTitle:@"Link" subtitle:_event.link url:_event.link]];
    for (GenericAsset *source in _event.sources) {
        NSString *subtitle = source.name;
        if (IsEmpty(subtitle))
            subtitle = source.url;
        [tableItems addObject:[self webPageItemWithTitle:NSLocalizedString(@"Web Resource", @"") subtitle:subtitle url:source.url]];
    }
    [__tableViewModel loadTableItems:tableItems inSection:SECTION_ADDITIONAL];
    [tableItems release];
}

- (void)configureNotifications {
    NSMutableArray *tableItems = [[NSMutableArray alloc] init];
    [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
        tableItem.text = NSLocalizedString(@"iCal", @"");
        tableItem.detailText = NSLocalizedString(@"Schedule this event in Calendar",@"");
        RKTableViewCellMapping *cellMapping = [self eventTableCellMap];
        tableItem.cellMapping = cellMapping;
        cellMapping.selectionStyle = UITableViewCellSelectionStyleBlue;
        cellMapping.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cellMapping.onSelectCell = ^(void) {
            EKEvent *ekEvent = self.event.ekEvent;
            if (!ekEvent)
                return;
            EKEventEditViewController *editor = [[SLFEventsManager sharedManager] newEventEditorForEvent:ekEvent delegate:self];
            editor.view.width = self.view.width;
            [self stackOrPushViewController:editor];
        };
    }]];
    if (SLFIsIOS5OrGreater()) {
        [tableItems addObject:[RKTableItem tableItemWithBlock:^(RKTableItem* tableItem) {
            SLFEventsManager *eventManager = [SLFEventsManager sharedManager];
            tableItem.detailText = [eventManager eventCalendar].title;
            tableItem.text = NSLocalizedString(@"Calendar",@"");
            RKTableViewCellMapping *cellMapping = [self eventTableCellMap];
            tableItem.cellMapping = cellMapping;
            if (!SLFIsIOS5OrGreater())
                return;
            cellMapping.selectionStyle = UITableViewCellSelectionStyleBlue;
            cellMapping.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cellMapping.onSelectCell = ^(void) {
                EKCalendarChooser *chooser = [eventManager newEventCalendarChooser:self];
                chooser.view.width = self.view.width;
               [self stackOrPushViewController:chooser];
            };
        }]];
    }
    [__tableViewModel loadTableItems:tableItems inSection:SECTION_NOTIFICATIONS];
    [tableItems release];
}

- (void)calendarDidChange:(NSNotification *)notification {
    [self configureNotifications];
}

- (void)configureParticipants {
    [__tableViewModel loadObjects:_event.participants.allObjects inSection:SECTION_PARTICIPANTS];    
}

- (RKTableViewCellMapping *)participantCellMap {
    RKTableViewCellMapping *cellMapping = [self eventTableCellMap];
    [cellMapping mapKeyPath:@"type" toAttribute:@"textLabel.text"];
    [cellMapping mapKeyPath:@"name" toAttribute:@"detailTextLabel.text"];
    return cellMapping;
}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action {
    self.event.ekEventIdentifier = controller.event.eventIdentifier;
    if (SLFIsIpad())
        [SLFAppDelegateStack popToViewController:self animated:YES];
    else
        [SLFAppDelegateNav popToViewController:self animated:YES];
}

- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller {
    return [[SLFEventsManager sharedManager] eventCalendar];
}

#pragma mark - Object Loader

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.title = NSLocalizedString(@"Load Error", @"");
    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    SLFEvent *event = nil;
    if (object && [object isKindOfClass:[SLFEvent class]]) {
        event = object;
    }
    [self reconfigureForEvent:event];
}

- (NSString *)headerForSectionIndex:(NSInteger)index {
    switch (index) {
        case SECTION_EVENT_INFO:
            return SectionHeaderEventInfo;
            break;
        case SECTION_PARTICIPANTS:
            return SectionHeaderParticipants;
            break;
        case SECTION_ADDITIONAL:
            return SectionHeaderAdditional;
            break;
        case SECTION_NOTIFICATIONS:
            return SectionHeaderNotifications;
            break;
        default:
            return @"";
            break;
    }
}
@end
