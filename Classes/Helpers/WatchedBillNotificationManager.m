//
//  WatchedBillNotificationManager.m
//  Created by Greg Combs on 12/3/11.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "WatchedBillNotificationManager.h"
#import "SLFPersistenceManager.h"
#import "SLFDataModels.h"
#import "SLFRestKitManager.h"
#import "NSDate+SLFDateHelper.h"
#import "BillDetailViewController.h"
#import "SLFAlertView.h"

@interface WatchedBillNotificationManager()
@property (nonatomic,assign) NSTimer *scheduleTimer;
@property (nonatomic,retain) RKRequestQueue *billRequestQueue;
- (IBAction)resetStatusNotifications:(id)sender;
- (IBAction)loadWatchedBillsFromNetwork:(id)sender;
- (BOOL)isBillStatusUpdated:(SLFBill *)foundBill;
@property (nonatomic,retain) NSMutableSet *updatedBills;
@end

@implementation WatchedBillNotificationManager
@synthesize billRequestQueue = _billRequestQueue;
@synthesize updatedBills = _updatedBills;
@synthesize scheduleTimer = _scheduleTimer;

+ (WatchedBillNotificationManager *)manager {
    return [[[WatchedBillNotificationManager alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _billRequestQueue = [RKRequestQueue newRequestQueueWithName:NSStringFromClass([self class])];
        _billRequestQueue.delegate = self;
        _billRequestQueue.concurrentRequestsLimit = 2;
        _billRequestQueue.showsNetworkActivityIndicatorWhenBusy = NO;
        _updatedBills = [[NSMutableSet alloc] init];
        [self performSelectorInBackground:@selector(checkBillsStatus:) withObject:self]; // check now
        self.scheduleTimer = [NSTimer scheduledTimerWithTimeInterval:SLF_HOURS_TO_SECONDS(2) target:self selector:@selector(checkBillsStatus:) userInfo:nil repeats:YES]; 
    }
    return self;
}

- (void)dealloc {
    [self.scheduleTimer invalidate];
    self.scheduleTimer = nil;
    [self.billRequestQueue cancelAllRequests];
    self.billRequestQueue = nil;
    self.updatedBills = nil;
    [super dealloc];
}

- (IBAction)checkBillsStatus:(id)sender {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self loadWatchedBillsFromNetwork:sender];
    [pool drain];
}

- (IBAction)loadWatchedBillsFromNetwork:(id)sender {
    NSDictionary *watchedBills = SLFWatchedBillsCatalog();
    if (IsEmpty(watchedBills))
        return;
    [self resetStatusNotifications:sender];
    SLFRestKitManager *restKit = [SLFRestKitManager sharedRestKit];
    for (NSString *watchID in [watchedBills allKeys]) {
        NSString *resourcePath = [SLFBill resourcePathForWatchID:watchID];
        RKObjectLoader *loader = [restKit objectLoaderForResourcePath:resourcePath delegate:self withTimeout:SLF_HOURS_TO_SECONDS(1)];
        [_billRequestQueue addRequest:loader];
    }
    if ([_billRequestQueue count])
        [_billRequestQueue start];
}

- (BOOL)isBillStatusUpdated:(SLFBill *)foundBill {
    if (!SLFBillIsWatched(foundBill))
        return NO;
    NSDictionary *watchedBills = SLFWatchedBillsCatalog();
    NSDate *previousUpdated = [watchedBills objectForKey:[foundBill watchID]];
    if (!previousUpdated || [[NSNull null] isEqual:previousUpdated])
        return NO;
    NSDate *currentUpdated = foundBill.dateUpdated;
    if (!currentUpdated || [[NSNull null] isEqual:currentUpdated])
        return NO;
    return [previousUpdated isEarlierThanDate:currentUpdated];
}

- (NSString *)alertMessageForUpdatedBill:(SLFBill *)updatedBill {
    if (!updatedBill)
        return nil;
    return [NSString stringWithFormat:NSLocalizedString(@"%@ (%@) has recently changed.  Select 'View Bill' to see the bill's current status.", @""), updatedBill.billID, updatedBill.state.name];
}

- (void)issueNotificationForBill:(SLFBill *)updatedBill {
    NSParameterAssert(updatedBill != NULL);
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.applicationIconBadgeNumber = [self.updatedBills count];
    notification.alertAction = NSLocalizedString(@"View Bill", @"");
    notification.alertBody = [self alertMessageForUpdatedBill:updatedBill];
    NSString *actionPath = [BillDetailViewController actionPathForObject:updatedBill];
    notification.userInfo = [NSDictionary dictionaryWithObject:actionPath forKey:@"ActionPath"];
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [notification release];
}

- (IBAction)resetStatusNotifications:(id)sender {
    [self.updatedBills removeAllObjects];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {
    if (![object isKindOfClass:[SLFBill class]])
        return;
    SLFBill *foundBill = object;
    if ([self isBillStatusUpdated:foundBill]) {
        [self.updatedBills addObject:foundBill];
        SLFTouchBillWatchedStatus(foundBill);
        [self issueNotificationForBill:foundBill];
    }
}

- (void)pruneInvalidResultIfNessesaryWithResourcePath:(NSString *)resourcePath {
    NSString *watchID = [SLFBill watchIDForResourcePath:resourcePath];
    if (IsEmpty(watchID))
        return;
    if (!SLFBillIsWatchedWithID(watchID))
        return;
    NSString *watchIDForDisplay = [[watchID stringByReplacingOccurrencesOfString:@"||" withString:@" "] uppercaseString];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Error for %@", @""), watchIDForDisplay];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"An error occurred while checking for updates to a watched bill, %@.  You may choose to ignore this error and keep the bill in your watch list for now, or you can opt to remove this bill in the event this error is not a temporary problem.", @""), watchIDForDisplay];
    [SLFAlertView showWithTitle:title message:message cancelTitle:NSLocalizedString(@"Keep", @"") cancelBlock:nil otherTitle:NSLocalizedString(@"Delete",@"") otherBlock:^{
        SLFRemoveWatchedBillWithWatchID(watchID);
    }];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    [SLFRestKitManager logFailureMessageForRequest:objectLoader error:error];
    [self pruneInvalidResultIfNessesaryWithResourcePath:objectLoader.resourcePath];
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
    [self pruneInvalidResultIfNessesaryWithResourcePath:objectLoader.resourcePath];
}

@end
