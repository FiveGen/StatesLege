//
//  LinksMasterViewController.h
//  TexLege
//
//  Created by Gregory Combs on 8/13/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TableDataSourceProtocol.h"
#import "GeneralTableViewController.h"
#import "AboutViewController.h"

@class MiniBrowserController;
@interface LinksMasterViewController : GeneralTableViewController {
}

@property (nonatomic,retain) IBOutlet AboutViewController *aboutControl;
@property (nonatomic,retain) IBOutlet MiniBrowserController *miniBrowser;

@end
