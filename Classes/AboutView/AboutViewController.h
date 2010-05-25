//
//  AboutViewController.h
//  TexLege
//
//  Created by Gregory S. Combs on 5/31/09.
//  Copyright 2009 Gregory S. Combs All rights reserved.
//

#import "Constants.h"

@protocol AboutViewControllerDelegate;


@interface AboutViewController : UIViewController <UIAlertViewDelegate> {
	id <AboutViewControllerDelegate> delegate;
	
	IBOutlet UILabel *versionLabel;
	IBOutlet UIView *infoView;
	//IBOutlet UIButton *projectWebsiteButton;
	IBOutlet UISegmentedControl *projectWebsiteButton;

	IBOutlet UIBarButtonItem *dismissButton;

	NSDictionary *infoPlistDict;
	NSURL *projectWebsiteURL;

}

@property (nonatomic, assign) id <AboutViewControllerDelegate> delegate;
@property (nonatomic, retain) NSDictionary *infoPlistDict;
@property (nonatomic, retain) NSURL *projectWebsiteURL;


- (IBAction)done:(id)sender;
- (IBAction)weblink_click:(id)sender;

- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle;
- (void) alertViewWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle otherTitle:(NSString *)otherTitle;


@property (retain) UILabel *versionLabel;
@property (retain) UIView *infoView;
@property (retain) UISegmentedControl *projectWebsiteButton;
@property (retain) UIBarButtonItem *dismissButton;
@end


@protocol AboutViewControllerDelegate
- (void)aboutViewControllerDidFinish:(AboutViewController *)controller;
@end

