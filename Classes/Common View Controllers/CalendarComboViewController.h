//
//  CalendarComboViewController.h
//  TexLege
//
//  Created by Gregory Combs on 7/29/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import <TapkuLibrary/TapkuLibrary.h>

@interface CalendarComboViewController : TKCalendarMonthTableViewController <UISplitViewControllerDelegate> {
	IBOutlet UIWebView	*webView;
	IBOutlet UIImageView *leftShadow, *rightShadow;
	IBOutlet UIImageView *portShadow, *landShadow;
	NSArray				*feedEntries;
	NSMutableArray	*currentEvents;
	NSMutableArray	*searchResults;

}
@property (nonatomic, retain) UIImageView *leftShadow, *rightShadow;
@property (nonatomic, retain) UIImageView *portShadow, *landShadow;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) NSArray *feedEntries;
@property (nonatomic, retain) NSMutableArray *currentEvents;
@property (nonatomic, retain) NSMutableArray *searchResults;

- (NSString *)popoverButtonTitle;
@end
