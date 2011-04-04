//
//  BillsDetailViewController.h
//  TexLege
//
//  Created by Gregory Combs on 2/20/11.
//  Copyright 2011 Gregory S. Combs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@class TableCellDataObject;
@class DDActionHeaderView;
@class BillVotesDataSource;
//@class BillStageStackPanel;
@interface BillsDetailViewController : UITableViewController <RKRequestDelegate, UISplitViewControllerDelegate, UIPopoverControllerDelegate> {
	IBOutlet NSMutableDictionary *bill;
	IBOutlet UIView *headerView, *descriptionView;
	IBOutlet UIView *statusView;
	IBOutlet UITextView *lab_description;
	IBOutlet UIButton *starButton;
	IBOutlet UILabel *stat_filed, *stat_thisPassComm, *stat_thisPassVote, *stat_thatPassComm, *stat_thatPassVote, *stat_governor, *stat_isLaw;
	IBOutlet DDActionHeaderView *actionHeader;
	id dataObject;
	BillVotesDataSource *voteDS;
}
@property (nonatomic,assign) id dataObject;

@property (nonatomic,retain) IBOutlet UIView *headerView, *descriptionView;
@property (nonatomic,retain) IBOutlet UIView *statusView;
@property (nonatomic,retain) IBOutlet UITextView *lab_description;
@property (nonatomic,retain) IBOutlet UIButton *starButton;
@property (nonatomic,retain) IBOutlet DDActionHeaderView *actionHeader;
@property (nonatomic,retain) IBOutlet UILabel *stat_filed, *stat_thisPassComm, *stat_thisPassVote, *stat_thatPassComm, *stat_thatPassVote, *stat_governor, *stat_isLaw;


@property (nonatomic,retain) UIPopoverController *masterPopover;
@property (nonatomic,retain) IBOutlet NSMutableDictionary *bill;

- (IBAction)resetTableData:(id)sender;

- (IBAction)starButtonToggle:(id)sender;

@end
