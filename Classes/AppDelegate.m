//
//  AppDelegate.m
//  Created by Gregory Combs on 7/31/11.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <RestKit/RestKit.h>

#import "AppDelegate.h"
#import "StatesViewController.h"
#import "SLFRestKitManager.h"
#import "SLFAppearance.h"
@interface AppDelegate()
- (void)setUpOnce;
- (void)setupAlways;
- (void)saveApplicationState;
@end

@implementation AppDelegate
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setUpOnce];
	StatesViewController* viewController = [[StatesViewController alloc] initWithStyle:UITableViewStylePlain];
	UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:viewController];    
    window.rootViewController = navController;
    [window makeKeyAndVisible];
    [viewController release];
    [navController release];
    return YES;
}

- (void)setUpOnce {
    RKLogSetAppLoggingLevel(RKLogLevelDebug);
    [SLFAppearance setupTheme];
    [SLFRestKitManager sharedRestKit];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self setupAlways];
}

/*- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self setupAlways];
}*/

- (void)setupAlways {
}

+ (void)initialize {
    /*
    if ([self class] == [AppDelegate class]) {
        NSDictionary *settings = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"selectedState"];
        [[NSUserDefaults standardUserDefaults] registerDefaults:settings];
    }
    */
}

- (void)saveApplicationState {
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveApplicationState];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveApplicationState];
}

- (void)dealloc {
    self.window = nil;
    [super dealloc];
}

@end
