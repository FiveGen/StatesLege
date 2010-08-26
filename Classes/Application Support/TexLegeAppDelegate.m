//
//  TexLegeAppDelegate.m
//  TexLege
//
//  Created by Gregory Combs on 7/22/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//

#import "TexLegeAppDelegate.h"
#import "UtilityMethods.h"
#import "PartisanIndexStats.h"

#import "Reachability.h"

#import "MiniBrowserController.h"
#import "CommonPopoversController.h"
#import "GeneralTableViewController.h"
#import "TableDataSourceProtocol.h"
#import "UIApplication+ScreenMirroring.h"
#import "AnalyticsOptInAlertController.h"

#import "LocalyticsSession.h"

#import "DistrictMapDataSource.h"

@interface TexLegeAppDelegate (Private)

- (void)setupFeatures;

- (NSString *)hostName;

- (void)restoreArchivableSavedTableSelection;
- (NSData *)archivableSavedTableSelection;
	
@end

// user default dictionary keys
NSString * const kRestoreSelectionKey = @"RestoreSelection";
NSString * const kAnalyticsOptInKey = @"HasOptedInToAnalytics";
NSString * const kShowedSplashScreenKey = @"HasShownSplashScreen";

NSUInteger kNumMaxTabs = 11;
NSInteger kNoSelection = -1;


@implementation TexLegeAppDelegate

@synthesize tabBarController;
@synthesize districtMapDataSource;
@synthesize savedTableSelection, appIsQuitting;

@synthesize mainWindow;
@synthesize aboutView, activeDialogController, analyticsOptInController;
@synthesize remoteHostStatus, internetConnectionStatus, localWiFiConnectionStatus;

@synthesize managedObjectContext;

@synthesize legislatorMasterVC, committeeMasterVC, capitolMapsMasterVC, linksMasterVC, calendarMasterVC, districtOfficeMasterVC;

+ (TexLegeAppDelegate *)appDelegate {
	return (TexLegeAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- init {
	if (self = [super init]) {
		// initialize  to nil
		mainWindow = nil;
		
		self.appIsQuitting = NO;
		self.savedTableSelection = [NSMutableDictionary dictionaryWithCapacity:2];
	}
	return self;
}

- (void)dealloc {
	self.districtMapDataSource = nil;
	self.savedTableSelection = nil;
	self.analyticsOptInController = nil;
	self.activeDialogController = nil;
	self.aboutView = nil;
	self.tabBarController = nil;
	self.mainWindow = nil;    
	
	self.capitolMapsMasterVC = nil;
	self.linksMasterVC = nil; 
	self.calendarMasterVC = nil;
	self.legislatorMasterVC = nil;
	self.committeeMasterVC = nil;
	self.districtOfficeMasterVC = nil;

	self.managedObjectContext = nil;
		
	if (managedObjectModel)
		[managedObjectModel release], managedObjectModel = nil;
	if (persistentStoreCoordinator)
		[persistentStoreCoordinator release], persistentStoreCoordinator = nil;
	
    [super dealloc];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	self.aboutView = nil;
	self.analyticsOptInController = nil;
}


#pragma mark -
#pragma mark Data Sources and Main View Controllers


////// IPAD ONLY
- (UISplitViewController *) splitViewController {
	if ([UtilityMethods isIPadDevice]) {
		if (![self.tabBarController.selectedViewController isKindOfClass:[UISplitViewController class]]) {
			debug_NSLog(@"Unexpected navigation controller class in tab bar controller hierarchy, check nib.");
			return nil;
		}
				
		return (UISplitViewController *)self.tabBarController.selectedViewController;
	}
	return nil;
}


- (UINavigationController *) masterNavigationController {
	if ([UtilityMethods isIPadDevice]) {
		UISplitViewController *split = [self splitViewController];
		if (split && split.viewControllers && [split.viewControllers count])
			return [split.viewControllers objectAtIndex:0];
	}
	else {
		if (![self.tabBarController.selectedViewController isKindOfClass:[UINavigationController class]]) {
			debug_NSLog(@"Unexpected view/navigation controller class in tab bar controller hierarchy, check nib.");
		}
		
		UINavigationController *nav = (UINavigationController *)self.tabBarController.selectedViewController;
		return nav;
	}
	return nil;
}

- (UINavigationController *) detailNavigationController {
	if ([UtilityMethods isIPadDevice]) {
		UISplitViewController *split = [self splitViewController];
		if (split && split.viewControllers && [split.viewControllers count])
			return [split.viewControllers objectAtIndex:1];
	}
	else
		return [self masterNavigationController];
	
	return nil;
}

- (UIViewController *) currentDetailViewController {	
	UINavigationController *nav = [self detailNavigationController];
	NSInteger numVCs = 0;
	if (nav && nav.viewControllers) {
		numVCs = [nav.viewControllers count];
		if ([UtilityMethods isIPadDevice])
			return numVCs ? [nav.viewControllers objectAtIndex:0] : nil;
		else if (numVCs >= 2)	// we're on an iPhone
			return [nav.viewControllers objectAtIndex:1];		// this will give us the second vc in the chain, typicaly a detail vc
	}

	return nil;
}

- (UIViewController *) currentMasterViewController {
	UINavigationController *nav = [self masterNavigationController];
	if (nav && nav.viewControllers && [nav.viewControllers count])
		return [nav.viewControllers objectAtIndex:0];
	return nil;
}


- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	if (![UtilityMethods isIPadDevice]) {
		if (![viewController isEqual:self.tabBarController.selectedViewController]) {
			//debug_NSLog(@"About to switch tabs, popping to root view controller.");
			UINavigationController *nav = [self detailNavigationController];
			if (nav)
				[nav popToRootViewControllerAnimated:YES];
		}
	}
	
	return YES;
}

- (void)tabBarController:(UITabBarController *)theTabBarController didSelectViewController:(UIViewController *)viewController {
	NSString *tabchangetag = [NSString stringWithFormat:@"SELECTTAB_%@", viewController.tabBarItem.title];
	[[LocalyticsSession sharedLocalyticsSession] tagEvent:tabchangetag];

	// Dismiss the popover if it's present.
	//if (self.menuPopoverPC != nil) {
	//	[self.menuPopoverPC dismissPopoverAnimated:YES];
	//}
	[[CommonPopoversController sharedCommonPopoversController] resetPopoverMenus:self];	
}

- (void)setTabOrderIfSaved {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *savedOrder = [defaults arrayForKey:@"savedTabOrder"];
	NSMutableArray *orderedTabs = [NSMutableArray arrayWithCapacity:[self.tabBarController.viewControllers count]];
	if ([savedOrder count] > 0 ) {
		for (NSInteger i = 0; i < [savedOrder count]; i++){
			for (UIViewController *aController in self.tabBarController.viewControllers) {
				if ([aController.tabBarItem.title isEqualToString:[savedOrder objectAtIndex:i]]) {
					[orderedTabs addObject:aController];
				}
			}
		}
		tabBarController.viewControllers = orderedTabs;
	}
}

- (void) setupFeatures {
	[[PartisanIndexStats sharedPartisanIndexStats] setManagedObjectContext:self.managedObjectContext];
	
	NSArray *nibObjects = nil;
	if ([UtilityMethods isIPadDevice]) 
		nibObjects = [[NSBundle mainBundle] loadNibNamed:@"iPadTabBarController" owner:self options:nil];
	else
		nibObjects = [[NSBundle mainBundle] loadNibNamed:@"iPhoneTabBarController" owner:self options:nil];
	
	if (!nibObjects || [nibObjects count] == 0) {
		debug_NSLog(@"Error loading user interface NIB components! Can't find the nib file and can't continue this charade.");
		exit(0);
	}
	
	NSArray *VCs = [[NSArray alloc] initWithObjects:self.legislatorMasterVC, self.committeeMasterVC, self.districtOfficeMasterVC,
					self.calendarMasterVC, self.capitolMapsMasterVC, self.linksMasterVC, nil];
	
	NSString * tempVCKey = [self.savedTableSelection objectForKey:@"viewController"];
	NSInteger savedTabSelectionIndex = -1;
	NSInteger loopIndex = 0;
	for (GeneralTableViewController *masterVC in VCs) {
		[masterVC configureWithManagedObjectContext:self.managedObjectContext];
		
		// If we have a preferred VC and we've found it in our array, save it
		if (savedTabSelectionIndex < 0 && tempVCKey && [tempVCKey isEqualToString:[masterVC viewControllerKey]]) // we have a saved view controller in mind
			savedTabSelectionIndex = loopIndex;
		loopIndex++;
	}
	if (savedTabSelectionIndex < 0 || savedTabSelectionIndex > [VCs count])
		savedTabSelectionIndex = 0;
	
	if ([UtilityMethods isIPadDevice]) {
		NSMutableArray *splitViewControllers = [[NSMutableArray alloc] initWithCapacity:[VCs count]];
		NSInteger index = 0;
		for (GeneralTableViewController * controller in VCs) {
			UISplitViewController * split = [controller splitViewController];
			if (split) {
				split.title = [[controller dataSource] name];
				split.tabBarItem = [[UITabBarItem alloc] initWithTitle:
									[[controller dataSource] name] image:[[controller dataSource] tabBarImage] tag:index];
				[splitViewControllers addObject:split];
			}
			index++;
		}
		[self.tabBarController setViewControllers:splitViewControllers];
		[splitViewControllers release];
	}
	[VCs release];
	
	id savedTabController = [self.tabBarController.viewControllers objectAtIndex:savedTabSelectionIndex];
	if (!savedTabController) {
		debug_NSLog (@"Couldn't find a view/navigation controller at index: %d", savedTabSelectionIndex);
		savedTabController = [self.tabBarController.viewControllers objectAtIndex:0];
	}
	
	[self setTabOrderIfSaved];
	
	[self.tabBarController setSelectedViewController:savedTabController];
	
	[self.mainWindow addSubview:self.tabBarController.view];
		
	self.districtMapDataSource = [[DistrictMapDataSource alloc] initWithManagedObjectContext:self.managedObjectContext];
	//[self.tabBarController setSelectedIndex:selection];
	[[CommonPopoversController sharedCommonPopoversController] resetPopoverMenus:nil];	
}


 - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{	
		
    [[Reachability sharedReachability] setHostName:[self hostName]];
    
    // The Reachability class is capable of notifying your application when the network
    // status changes. By default, those notifications are not enabled.
    [[Reachability sharedReachability] setNetworkStatusNotificationsEnabled:YES];
        
    [self updateStatus];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:@"kNetworkReachabilityChangedNotification" object:nil];
	
    // Set up the mainWindow and content view
	UIWindow *localMainWindow;
	localMainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.mainWindow = localMainWindow;
	[localMainWindow release];
	
    [self.mainWindow setBackgroundColor:[UIColor whiteColor]];
	
	[self restoreArchivableSavedTableSelection];
	[self setupFeatures];
			
	// make the window visible
	[self.mainWindow makeKeyAndVisible];

	
	// register our preference selection data to be archived
	NSDictionary *savedPrefsDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									[self archivableSavedTableSelection],kRestoreSelectionKey,
									[NSNumber numberWithInteger:-1], kAnalyticsOptInKey,
									[NSNumber numberWithBool:NO], kShowedSplashScreenKey,
									nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:savedPrefsDict];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	self.analyticsOptInController = [[AnalyticsOptInAlertController alloc] init];
	if (self.analyticsOptInController && [self.analyticsOptInController shouldPresentAnalyticsOptInAlert])
		[self.analyticsOptInController presentAnalyticsOptInAlert];
		
	[[LocalyticsSession sharedLocalyticsSession] startSession:@"111c245bdf4ad08686ac12b-eae4b72e-9439-11df-5b0c-009ee7c87684"];
	
	if ([UtilityMethods supportsMKPolyline])
		debug_NSLog(@"MKPolyline IS available on this device.");
	else
		debug_NSLog(@"MKPolyline is NOT available on this device.");
	
	return YES;
}



- (void)prepareToQuit {
	if (self.appIsQuitting)
		return;
	self.appIsQuitting = YES;
	
	if (self.tabBarController) {
		// Smarten this up later for Core Data tab saving
		NSMutableArray *savedOrder = [NSMutableArray arrayWithCapacity:[self.tabBarController.viewControllers count]];
		NSArray *tabOrderToSave = self.tabBarController.viewControllers;
		
		for (UIViewController *aViewController in tabOrderToSave) {
			[savedOrder addObject:aViewController.tabBarItem.title];
		}
		[[NSUserDefaults standardUserDefaults] setObject:savedOrder forKey:@"savedTabOrder"];
	}
	
	// save the drill-down hierarchy of selections to preferences
	[[NSUserDefaults standardUserDefaults] setObject:[self archivableSavedTableSelection] forKey:kRestoreSelectionKey];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Core Data Saving
	[self saveAction:nil];	
}



- (void)applicationDidBecomeActive:(UIApplication *)application		{[[UIApplication sharedApplication] setupScreenMirroring];}

- (void)applicationWillResignActive:(UIApplication *)application	{[[UIApplication sharedApplication] disableScreenMirroring];}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	self.appIsQuitting = NO;
	
 	[[LocalyticsSession sharedLocalyticsSession] resume];
 	[[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[self prepareToQuit];
	[[LocalyticsSession sharedLocalyticsSession] close];
	[[LocalyticsSession sharedLocalyticsSession] upload];	
}

- (void)applicationWillTerminate:(UIApplication *)application {	
	[self prepareToQuit];
	[[LocalyticsSession sharedLocalyticsSession] close];
	[[LocalyticsSession sharedLocalyticsSession] upload];	
}


#pragma mark -
#pragma mark Alerts and Dialog Boxes


- (void)showAboutDialog:(UIViewController *)controller {
	if (![UtilityMethods isIPadDevice]) {
		if (!controller)
			return;
		
		self.activeDialogController = controller;
		
		if (!self.aboutView) {
			self.aboutView = [[TexLegeInfoController alloc] initWithNibName:@"TexLegeInfoController~iphone" bundle:nil];	
			self.aboutView.delegate = self;
			self.aboutView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
			self.aboutView.modalPresentationStyle = UIModalPresentationFormSheet;
		}
		
		if (self.aboutView)
			[controller presentModalViewController:self.aboutView animated:YES];
	}
}

- (void)modalViewControllerDidFinish:(UIViewController *)controller {
	if (![UtilityMethods isIPadDevice] && self.activeDialogController) {
		BOOL isAbout = [self.activeDialogController.modalViewController isEqual:self.aboutView];
		
		[self.activeDialogController dismissModalViewControllerAnimated:YES];
		if (isAbout)
			self.aboutView = nil;
	}
}

/*
 
 // add this to init: or something
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
 (void)deviceOrientationDidChange:(void*)object { UIDeviceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
 
 if (UIInterfaceOrientationIsLandscape(orientation)) {
 // do something
 } else {
 // do something else
 }
 }
 // add this to done: or something
 [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
 
 */


/*
 - (void)application:(UIApplication *)application willChangeStatusBarOrientation:(UIInterfaceOrientation)newStatusBarOrientation duration:(NSTimeInterval)duration {
	// a cheat, so that we can dismiss all our popovers, if they're open.
}*/

#pragma mark - 
#pragma mark Reachability

/*
 Remote Host Reachable
 Not reachable | Reachable via EDGE | Reachable via WiFi
 
 Connection to Internet
 Not available | Available via EDGE | Available via WiFi
 
 Connection to Local Network.
 Not available | Available via WiFi
*/

- (void)reachabilityChanged:(NSNotification *)note
{
    [self updateStatus];
}

- (void)updateStatus
{
    // Query the SystemConfiguration framework for the state of the device's network connections.
    self.remoteHostStatus           = [[Reachability sharedReachability] remoteHostStatus];
    self.internetConnectionStatus    = [[Reachability sharedReachability] internetConnectionStatus];
    self.localWiFiConnectionStatus    = [[Reachability sharedReachability] localWiFiConnectionStatus];
}


- (BOOL)isCarrierDataNetworkActive
{
    return (self.remoteHostStatus == ReachableViaCarrierDataNetwork);
}

- (NSString *)hostName
{	return @"www.apple.com";	}

- (NSString *)hostNameLabel
{	return [NSString stringWithFormat:@"Remote Host: %@", [self hostName]];	}

#pragma mark -
#pragma mark Saving

- (id) savedTableSelectionForKey:(NSString *)vcKey {
	id object = nil;
	id savedVC = [self.savedTableSelection objectForKey:@"viewController"];
	if (vcKey && savedVC && [vcKey isEqualToString:savedVC])
		object = [self.savedTableSelection objectForKey:@"object"];
	
	return object;
}

- (void)setSavedTableSelection:(id)object forKey:(NSString *)vcKey {
	if (!vcKey) {
		[self.savedTableSelection removeAllObjects];
		return;
	}
	[self.savedTableSelection setObject:vcKey forKey:@"viewController"];
	if (object)
		[self.savedTableSelection setObject:object forKey:@"object"];
	else
		[self.savedTableSelection removeObjectForKey:@"object"];
}

- (void)restoreArchivableSavedTableSelection {
	NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kRestoreSelectionKey];
	if (data) {
		NSMutableDictionary *tempDict = [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];	
		if (tempDict) {
			id object = [tempDict objectForKey:@"object"];
			if (object && [object isKindOfClass:[NSURL class]] && [[object scheme] isEqualToString:@"x-coredata"])	{		// try to get a managed object ID				
				NSManagedObjectID *tempID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation:object];
				if (tempID)
					[tempDict setObject:tempID forKey:@"object"]; 
			}
			
			self.savedTableSelection = tempDict;
			[tempDict release];
		}	
	}
}

- (NSData *)archivableSavedTableSelection {
	NSMutableDictionary *tempDict = [self.savedTableSelection mutableCopy];
	id object = [tempDict objectForKey:@"object"];
	if (object && [object isKindOfClass:[NSManagedObjectID class]])
		[tempDict setObject:[object URIRepresentation] forKey:@"object"]; 

	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:tempDict];
	[tempDict release];
	return data;
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (IBAction)saveAction:(id)sender {
	
    NSError *error;
    if (managedObjectContext != nil) {
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
			// Handle error.
			debug_NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	NSString *path = [[NSBundle mainBundle] pathForResource:@"TexLege" ofType:@"momd"];
	NSURL *momURL = [NSURL fileURLWithPath:path];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];

    //managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
	static NSString *DATABASE_NAME = @"TexLege.v2";
	//static NSString *DATABASE_FILE = @"TexLege.v2.sqlite";
	
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
	// If we ever want to allow editing or changing the database, we must use a copy of the database!
#ifdef IF_WE_ALLOW_SAVING_IN_CORE_DATA_USE_A_COPY_OF_THE_DB
	NSString *storePath = [[UtilityMethods applicationDocumentsDirectory] stringByAppendingPathComponent: DATABASE_FILE];
	
	#if NEEDS_TO_INITIALIZE_DATABASE == 0 // don't use this if we're setting up & initializing from property lists...
	/*
	 Set up the store.
	 Provide a pre-populated default store.
	 */
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:DATABASE_NAME ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	#endif
#else
	NSString *storePath = [[NSBundle mainBundle] pathForResource:DATABASE_NAME ofType:@"sqlite"];
#endif
	debug_NSLog(@"%@", storePath);
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];

	NSError *error;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], 
							 NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], 
							 NSInferMappingModelAutomaticallyOption, nil];
	
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Handle the error.
		debug_NSLog(@"error: %@", [error localizedFailureReason]);
    }    
		
    return persistentStoreCoordinator;
}


@end

