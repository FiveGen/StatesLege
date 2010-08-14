//
//  GeneralTableViewController.h
//  TexLege
//
//  Created by Gregory Combs on 7/10/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//

#import "Constants.h"

#import "TableDataSourceProtocol.h"
@interface GeneralTableViewController : UITableViewController <UITableViewDelegate> {
}

@property (nonatomic,retain) IBOutlet id<TableDataSource> dataSource;
@property (nonatomic,retain) IBOutlet id detailViewController;
@property (nonatomic,readonly) NSString			*viewControllerKey;
@property (nonatomic,retain) id					selectObjectOnAppear;

- (void)configureWithDataSourceClass:(Class)sourceClass andManagedObjectContext:(NSManagedObjectContext *)context;
- (void)runLoadView;

@end
